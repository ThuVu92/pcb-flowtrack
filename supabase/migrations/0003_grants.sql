-- Stage 1+2 fix: tables created via the SQL Editor don't automatically get
-- the base table-level privileges Supabase's dashboard normally grants.
-- Row Level Security policies only take effect once a role has these
-- underlying GRANTs — without them, PostgREST gets "permission denied"
-- before RLS is even evaluated. Run this after 0001 and 0002.

grant usage on schema public to anon, authenticated;

-- Anyone logged in (authenticated) can attempt any operation on these
-- tables — RLS policies from 0001/0002 are what actually decide, per row,
-- whether a given user may read/write. Anonymous (anon, pre-login) only
-- needs SELECT on depts, for the signup screen's department dropdown.

grant select, insert, update, delete on
  public.depts,
  public.stages,
  public.profiles,
  public.jobs,
  public.drawings,
  public.drawing_versions,
  public.assigns,
  public.assign_comments,
  public.assign_last_seen,
  public.notifs,
  public.timelogs,
  public.timelog_drawings
to authenticated;

grant select on public.depts to anon;
