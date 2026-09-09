-- ============================================================
-- FIX: profiles RLS violation on signup
-- Run this in: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- 1. Trigger function: runs as superuser, bypasses RLS entirely.
--    Reads name/org_name/user_type from the metadata passed at signUp().
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, org_name, user_type)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'User'),
    nullif(new.raw_user_meta_data->>'org_name', ''),
    coalesce(new.raw_user_meta_data->>'user_type', 'donor')
  )
  on conflict (id) do nothing;   -- safe to re-run
  return new;
end;
$$;

-- 2. Fire the trigger after every new auth user is created.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 3. The client-side INSERT to profiles is no longer needed, but keep
--    the RLS policy so users can still read/update their own row.
--    (No changes needed to existing policies.)
