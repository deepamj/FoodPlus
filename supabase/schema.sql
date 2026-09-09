-- ============================================================
-- FoodPlus Database Schema
-- Apply in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

create extension if not exists "pgcrypto";

-- -------------------------------------------------------
-- PROFILES
-- -------------------------------------------------------
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null,
  org_name    text,
  user_type   text not null check (user_type in ('donor', 'ngo')),
  created_at  timestamptz not null default now()
);
alter table profiles enable row level security;
create policy "profiles: own row" on profiles for all using (auth.uid() = id);
create policy "profiles: anon read all" on profiles for select using (
  auth.uid() is not null
);

-- -------------------------------------------------------
-- POSTS
-- -------------------------------------------------------
create table if not exists posts (
  id          uuid primary key default gen_random_uuid(),
  donor_id    uuid not null references profiles(id) on delete cascade,
  address     text not null,
  lat         double precision,
  lng         double precision,
  status      text not null default 'posted' check (status in ('posted','claimed','collected')),
  expires_at  timestamptz,
  created_at  timestamptz not null default now()
);
alter table posts enable row level security;
create policy "posts: donor owns" on posts for all using (auth.uid() = donor_id);
create policy "posts: anon reads posted" on posts for select using (
  status = 'posted' and auth.uid() is not null
);

-- -------------------------------------------------------
-- POST_ITEMS
-- -------------------------------------------------------
create table if not exists post_items (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references posts(id) on delete cascade,
  name        text not null,
  quantity    int not null check (quantity > 0),
  available   int not null check (available >= 0),
  is_veg      boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table post_items enable row level security;
create policy "post_items: donor owns" on post_items for all using (
  exists (select 1 from posts po where po.id = post_id and po.donor_id = auth.uid())
);
create policy "post_items: ngo reads" on post_items for select using (
  exists (
    select 1 from posts po where po.id = post_id and po.status = 'posted'
    and auth.uid() is not null
  )
);

-- -------------------------------------------------------
-- POST_PHOTOS
-- -------------------------------------------------------
create table if not exists post_photos (
  id            uuid primary key default gen_random_uuid(),
  post_id       uuid not null references posts(id) on delete cascade,
  storage_path  text not null,
  created_at    timestamptz not null default now()
);
alter table post_photos enable row level security;
create policy "post_photos: donor owns" on post_photos for all using (
  exists (select 1 from posts po where po.id = post_id and po.donor_id = auth.uid())
);
create policy "post_photos: ngo reads" on post_photos for select using (
  exists (
    select 1 from posts po where po.id = post_id and po.status in ('posted','claimed')
    and auth.uid() is not null
  )
);

-- -------------------------------------------------------
-- CLAIMS
-- -------------------------------------------------------
create table if not exists claims (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid not null references posts(id) on delete cascade,
  ngo_id      uuid not null references profiles(id) on delete cascade,
  quantities  jsonb not null default '{}',
  claimed_at  timestamptz not null default now()
);
alter table claims enable row level security;
create policy "claims: ngo insert" on claims for insert with check (auth.uid() = ngo_id);
create policy "claims: ngo read own" on claims for select using (auth.uid() = ngo_id);
create policy "claims: donor reads" on claims for select using (
  exists (select 1 from posts po where po.id = post_id and po.donor_id = auth.uid())
);

-- -------------------------------------------------------
-- RPC: claim_post (atomic claim + decrement)
-- -------------------------------------------------------
create or replace function claim_post(
  p_post_id    uuid,
  p_ngo_id     uuid,
  p_quantities jsonb
)
returns void language plpgsql security definer as $$
declare
  item_row record;
  claimed  int;
begin
  if not exists (select 1 from posts where id = p_post_id and status = 'posted') then
    raise exception 'Post is no longer available';
  end if;
  for item_row in select id, available from post_items where post_id = p_post_id loop
    claimed := (p_quantities ->> item_row.id::text)::int;
    if claimed is null then continue; end if;
    if claimed > item_row.available then
      raise exception 'Quantity exceeds available for item %', item_row.id;
    end if;
    update post_items set available = available - claimed where id = item_row.id;
  end loop;
  insert into claims (post_id, ngo_id, quantities) values (p_post_id, p_ngo_id, p_quantities);
  update posts set status = 'claimed' where id = p_post_id;
end;
$$;

-- -------------------------------------------------------
-- STORAGE: post-photos bucket
-- -------------------------------------------------------
insert into storage.buckets (id, name, public)
  values ('post-photos', 'post-photos', true)
  on conflict (id) do nothing;

create policy "storage: auth upload" on storage.objects
  for insert with check (bucket_id = 'post-photos' and auth.uid() is not null);

create policy "storage: public read" on storage.objects
  for select using (bucket_id = 'post-photos');

create policy "storage: owner delete" on storage.objects
  for delete using (bucket_id = 'post-photos' and auth.uid()::text = (storage.foldername(name))[1]);
