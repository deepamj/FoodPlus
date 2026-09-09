-- ============================================================
-- REMOVE ROLE FILTERS: any authenticated user can see surplus
-- Run in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- profiles: any auth user may read donor info (for post feed / claimers)
drop policy if exists "profiles: ngo read all" on profiles;
drop policy if exists "profiles: anon read all" on profiles;
create policy "profiles: anon read all" on profiles for select using (
  auth.uid() is not null
);

-- posts: any auth user may read posted surplus
drop policy if exists "posts: ngo reads posted" on posts;
drop policy if exists "posts: anon reads posted" on posts;
create policy "posts: anon reads posted" on posts for select using (
  status = 'posted' and auth.uid() is not null
);

-- post_items: any auth user may read items of posted surplus
drop policy if exists "post_items: ngo reads" on post_items;
create policy "post_items: ngo reads" on post_items for select using (
  exists (
    select 1 from posts po where po.id = post_id and po.status = 'posted'
    and auth.uid() is not null
  )
);

-- post_photos: any auth user may read photos of posted/claimed surplus
drop policy if exists "post_photos: ngo reads" on post_photos;
create policy "post_photos: ngo reads" on post_photos for select using (
  exists (
    select 1 from posts po where po.id = post_id and po.status in ('posted','claimed')
    and auth.uid() is not null
  )
);