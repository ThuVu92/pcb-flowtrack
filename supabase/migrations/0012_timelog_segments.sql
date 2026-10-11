-- Work segments: one row per continuous stretch of work on a timelog.
-- Start/Resume opens a segment, Pause/Finish closes it. Lets reports split a
-- task that is paused overnight and resumed the next day across the days it
-- was actually worked (previously only start_at/paused_ms/end_at existed, so
-- all time landed on the start day). end_at IS NULL = segment still running.
create table timelog_segments (
  id uuid primary key default gen_random_uuid(),
  timelog_id uuid not null references timelogs(id) on delete cascade,
  start_at timestamptz not null,
  end_at timestamptz
);
create index timelog_segments_timelog_idx on timelog_segments(timelog_id);

alter table timelog_segments enable row level security;

create policy "timelog_segments_read_own_or_manager" on timelog_segments for select
  using (exists (
    select 1 from timelogs t where t.id = timelog_id
    and (t.user_id = auth.uid() or my_role() in ('admin','manager'))
  ));
create policy "timelog_segments_insert_own" on timelog_segments for insert
  with check (exists (select 1 from timelogs t where t.id = timelog_id and t.user_id = auth.uid()));
create policy "timelog_segments_update_own" on timelog_segments for update
  using (exists (select 1 from timelogs t where t.id = timelog_id and t.user_id = auth.uid()));
create policy "timelog_segments_delete_manager" on timelog_segments for delete
  using (exists (
    select 1 from timelogs t where t.id = timelog_id and my_role() in ('admin','manager')
  ));

grant select, insert, update, delete on timelog_segments to authenticated;

alter publication supabase_realtime add table timelog_segments;

-- Backfill: one compressed segment per existing timelog, starting at start_at
-- with the length of time actually worked, so every existing total is
-- unchanged (old data stays on its start day — the pause points were never
-- recorded, so it can't be split). Running logs get an open segment whose
-- start is shifted by the paused time, so now() - start still equals the old
-- elapsed value.
insert into timelog_segments (timelog_id, start_at, end_at)
select t.id,
  case when t.status = 'running' then t.start_at + (coalesce(t.paused_ms,0) || ' milliseconds')::interval
       else t.start_at end,
  case when t.status = 'running' then null
       else t.start_at + greatest(
              coalesce(t.end_at, t.paused_at, t.start_at) - t.start_at - (coalesce(t.paused_ms,0) || ' milliseconds')::interval,
              interval '0')
  end
from timelogs t;
