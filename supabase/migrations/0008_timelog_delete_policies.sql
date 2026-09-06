-- The app's own UI never deletes timelogs/timelog_drawings/timelog_stages,
-- so these never got a DELETE policy. Without one, RLS silently denies any
-- delete (0 rows affected, no error) instead of throwing — this repeatedly
-- blocked cleaning up test data via the SQL Editor during development.
-- Scope deletion to admin/manager only, same as jobs/drawings deletion.

create policy "timelogs_delete_manager" on timelogs for delete
  using (my_role() in ('admin','manager'));

create policy "timelog_drawings_delete_manager" on timelog_drawings for delete
  using (exists (
    select 1 from timelogs t where t.id = timelog_id and my_role() in ('admin','manager')
  ));

create policy "timelog_stages_delete_manager" on timelog_stages for delete
  using (exists (
    select 1 from timelogs t where t.id = timelog_id and my_role() in ('admin','manager')
  ));

grant delete on timelog_stages to authenticated;
