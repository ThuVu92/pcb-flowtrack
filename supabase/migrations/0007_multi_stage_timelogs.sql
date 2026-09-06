-- Allows one timelog entry to cover multiple stages at once (time split
-- evenly across them for reporting), mirroring how timelog_drawings already
-- lets one entry cover multiple drawings. The old single `stage` text
-- column on timelogs stays as-is for now (unused by new writes, harmless).
create table timelog_stages (
  timelog_id uuid references timelogs(id) on delete cascade,
  stage text not null,
  primary key (timelog_id, stage)
);

alter table timelog_stages enable row level security;

create policy "timelog_stages_read_own_or_manager" on timelog_stages for select
  using (exists (
    select 1 from timelogs t where t.id = timelog_id
    and (t.user_id = auth.uid() or my_role() in ('admin','manager'))
  ));
create policy "timelog_stages_insert_own" on timelog_stages for insert
  with check (exists (select 1 from timelogs t where t.id = timelog_id and t.user_id = auth.uid()));

grant select, insert on timelog_stages to authenticated;

alter publication supabase_realtime add table timelog_stages;
