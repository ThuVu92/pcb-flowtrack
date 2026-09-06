-- Fix: 0001 never granted a DELETE policy on profiles, so rejectUser()
-- (Admin rejecting a pending signup) silently deleted 0 rows instead of
-- removing the profile — Postgres RLS filters DELETE targets rather than
-- raising an error when no policy matches, so this went unnoticed until
-- manual testing confirmed the row was never actually removed.

create policy "profiles_delete_admin" on profiles for delete
  using (my_role() = 'admin');
