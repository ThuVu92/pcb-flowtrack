-- Employees can only SELECT their own rows in `timelogs` (see
-- timelogs_read_own_or_manager, migration 0002), so the client-side Home
-- page "Job progress" calc (computeOrderProgress in index.html), which
-- reads straight from the in-memory TIMELOGS array, silently under-counts
-- for employee accounts — it only sees their own contribution to a Job,
-- not the company-wide picture.
--
-- Rather than loosening RLS (which would expose every employee's raw
-- timelogs to everyone) this adds a `security definer` function — same
-- pattern as my_role()/my_status() in migration 0001 — that computes and
-- returns ONLY the aggregate (job_code, pct, status) per Job, never any
-- row identifying who did the work or how long it took. Mirrors the exact
-- logic of computeOrderProgress() in index.html.
create or replace function job_progress_summary()
returns table(job_code text, pct int, status text)
language sql security definer stable as $$
  with timelog_job_expanded as (
    -- One row per (timelog, job) — from timelog_jobs when present, else
    -- fall back to the legacy single timelogs.job_code column, exactly
    -- like mapTimelog()'s jobCodes fallback on the client.
    select t.id as timelog_id, coalesce(tj.job_code, t.job_code) as job_code, t.status
    from timelogs t
    left join timelog_jobs tj on tj.timelog_id = t.id
  ),
  timelog_no_drawing as (
    select t.id from timelogs t
    where not exists (select 1 from timelog_drawings td where td.timelog_id = t.id)
  ),
  drawing_status as (
    select d.code as drawing_code, d.job_code,
      exists(
        select 1 from timelog_drawings td join timelogs t on t.id = td.timelog_id
        where td.drawing_code = d.code
      ) as started,
      exists(
        select 1 from timelog_drawings td join timelogs t on t.id = td.timelog_id
        where td.drawing_code = d.code and t.status = 'done'
      ) as any_done
    from drawings d
  ),
  job_drawing_agg as (
    select job_code,
      count(*) as total_drawings,
      count(*) filter (where any_done) as done_drawings,
      bool_or(started) as any_started
    from drawing_status
    where job_code is not null
    group by job_code
  ),
  generic_agg as (
    select tje.job_code,
      count(*) as generic_count,
      bool_or(tje.status <> 'done') as generic_any_unfinished
    from timelog_job_expanded tje
    join timelog_no_drawing tnd on tnd.id = tje.timelog_id
    where tje.job_code is not null
    group by tje.job_code
  )
  select j.code as job_code,
    case
      when coalesce(jda.total_drawings, 0) = 0 then 0
      else round((coalesce(jda.done_drawings, 0)::numeric / jda.total_drawings) * 100)::int
    end as pct,
    case
      when coalesce(jda.total_drawings, 0) = 0 then
        case when coalesce(ga.generic_count, 0) > 0 then 'progress' else 'idle' end
      when jda.done_drawings = jda.total_drawings and not coalesce(ga.generic_any_unfinished, false) then 'done'
      when coalesce(jda.any_started, false) or coalesce(ga.generic_count, 0) > 0 then 'progress'
      else 'idle'
    end as status
  from jobs j
  left join job_drawing_agg jda on jda.job_code = j.code
  left join generic_agg ga on ga.job_code = j.code
$$;

grant execute on function job_progress_summary() to authenticated;
