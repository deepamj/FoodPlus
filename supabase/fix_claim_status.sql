-- ============================================================
-- FIX: post only becomes 'claimed' when every item is fully claimed
-- Run in: Supabase Dashboard → SQL Editor → Run
-- (idempotent — safe to re-run)
-- ============================================================

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
  -- Mark claimed only when every parcel is claimed (available = 0 for all items)
  if not exists (select 1 from post_items where post_id = p_post_id and available > 0) then
    update posts set status = 'claimed' where id = p_post_id;
  end if;
end;
$$;