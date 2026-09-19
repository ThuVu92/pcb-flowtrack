-- Allows one timelog entry to cover multiple Jobs at once (time split evenly
-- across them for reporting), mirroring how timelog_drawings/timelog_stages
-- already let one entry cover multiple drawings/stages. The old single
-- `job_code` column on timelogs stays as-is for now (unused by new reads,
-- still written as the first selected Job for safety/quick SQL lookups).
create table timelog_jobs (
  timelog_id uuid references timelogs(id) on delete cascade,
  job_code text references jobs(code),
  primary key (timelog_id, job_code)
);

alter table timelog_jobs enable row level security;

create policy "timelog_jobs_read_own_or_manager" on timelog_jobs for select
  using (exists (
    select 1 from timelogs t where t.id = timelog_id
    and (t.user_id = auth.uid() or my_role() in ('admin','manager'))
  ));
create policy "timelog_jobs_insert_own" on timelog_jobs for insert
  with check (exists (select 1 from timelogs t where t.id = timelog_id and t.user_id = auth.uid()));
create policy "timelog_jobs_delete_manager" on timelog_jobs for delete
  using (exists (
    select 1 from timelogs t where t.id = timelog_id and my_role() in ('admin','manager')
  ));

grant select, insert, delete on timelog_jobs to authenticated;

alter publication supabase_realtime add table timelog_jobs;
