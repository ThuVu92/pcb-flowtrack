-- Stage 2: Core workflow — jobs, drawings, task assignment, time tracking
-- Apply after 0001_stage1_auth_users_depts.sql, in the Supabase SQL Editor.

-- ---------- Jobs (was ORDERS) & drawings ----------
create table jobs (
  code text primary key,
  name_vi text,
  name_en text,
  name_ja text,
  plan_date date,
  priority text check (priority in ('high','medium','low')),
  memo text default '',
  updated_at timestamptz default now()
);

create table drawings (
  code text primary key,
  name text not null,
  job_code text references jobs(code) on delete set null,
  qty int default 0,
  updated_at timestamptz default now()
);

create table drawing_versions (
  id uuid primary key default gen_random_uuid(),
  drawing_code text references drawings(code) on delete cascade,
  version text not null,
  issue_date date,
  created_at timestamptz default now()
);

-- ---------- Task assignment ----------
create table assigns (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  by_user uuid references profiles(id),
  to_user uuid references profiles(id),
  job_code text references jobs(code),
  drawing_code text references drawings(code),
  status text not null default 'sent'
    check (status in ('sent','accepted','inprogress','done','rejected')),
  reject_reason text default '',
  created_at timestamptz default now()
);

create table assign_comments (
  id uuid primary key default gen_random_uuid(),
  assign_id uuid references assigns(id) on delete cascade,
  by_user uuid references profiles(id),
  text text not null,
  created_at timestamptz default now()
);

create table assign_last_seen (
  assign_id uuid references assigns(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  seen_count int default 0,
  primary key (assign_id, user_id)
);

-- ---------- Notifications ----------
create table notifs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  text text not null,
  read boolean default false,
  created_at timestamptz default now()
);

-- ---------- Time tracking ----------
create table timelogs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  job_code text references jobs(code),
  drawing_name text,
  dept_id uuid references depts(id),
  stage text,
  start_at timestamptz not null default now(),
  paused_at timestamptz,
  paused_ms bigint default 0,
  end_at timestamptz,
  status text not null default 'running' check (status in ('running','paused','done'))
);

create table timelog_drawings (
  timelog_id uuid references timelogs(id) on delete cascade,
  drawing_code text references drawings(code),
  primary key (timelog_id, drawing_code)
);

-- ---------- Row Level Security ----------
alter table jobs enable row level security;
alter table drawings enable row level security;
alter table drawing_versions enable row level security;
alter table assigns enable row level security;
alter table assign_comments enable row level security;
alter table assign_last_seen enable row level security;
alter table notifs enable row level security;
alter table timelogs enable row level security;
alter table timelog_drawings enable row level security;

-- Jobs & drawings: everyone (active users) can read; only admin/manager can write.
create policy "jobs_read_all" on jobs for select using (my_status() = 'active');
create policy "jobs_write_manager" on jobs for insert with check (my_role() in ('admin','manager'));
create policy "jobs_update_manager" on jobs for update using (my_role() in ('admin','manager'));
create policy "jobs_delete_manager" on jobs for delete using (my_role() in ('admin','manager'));

create policy "drawings_read_all" on drawings for select using (my_status() = 'active');
create policy "drawings_write_manager" on drawings for insert with check (my_role() in ('admin','manager'));
create policy "drawings_update_manager" on drawings for update using (my_role() in ('admin','manager'));
create policy "drawings_delete_manager" on drawings for delete using (my_role() in ('admin','manager'));

create policy "drawing_versions_read_all" on drawing_versions for select using (my_status() = 'active');
create policy "drawing_versions_write_manager" on drawing_versions for insert with check (my_role() in ('admin','manager'));
create policy "drawing_versions_delete_manager" on drawing_versions for delete using (my_role() in ('admin','manager'));

-- Assigns: an employee sees/updates only assigns where they're the sender or
-- recipient; admin/manager see and create all.
create policy "assigns_read_own_or_manager" on assigns for select
  using (my_status() = 'active' and (by_user = auth.uid() or to_user = auth.uid() or my_role() in ('admin','manager')));
create policy "assigns_insert_manager" on assigns for insert
  with check (my_role() in ('admin','manager') and my_status() = 'active');
create policy "assigns_update_participant" on assigns for update
  using (to_user = auth.uid() or my_role() in ('admin','manager'));

create policy "assign_comments_read_participant" on assign_comments for select
  using (exists (
    select 1 from assigns a where a.id = assign_id
    and (a.by_user = auth.uid() or a.to_user = auth.uid() or my_role() in ('admin','manager'))
  ));
create policy "assign_comments_insert_participant" on assign_comments for insert
  with check (exists (
    select 1 from assigns a where a.id = assign_id
    and (a.by_user = auth.uid() or a.to_user = auth.uid() or my_role() in ('admin','manager'))
  ));

create policy "assign_last_seen_own" on assign_last_seen for select using (user_id = auth.uid());
create policy "assign_last_seen_upsert_own" on assign_last_seen for insert with check (user_id = auth.uid());
create policy "assign_last_seen_update_own" on assign_last_seen for update using (user_id = auth.uid());

-- Notifications: only the owner can read/update their own.
create policy "notifs_read_own" on notifs for select using (user_id = auth.uid());
create policy "notifs_update_own" on notifs for update using (user_id = auth.uid());
create policy "notifs_insert_any_active" on notifs for insert with check (my_status() = 'active');

-- Timelogs: an employee reads/writes only their own; admin/manager read all
-- (for the dashboard) but only the owning employee starts/pauses/finishes.
create policy "timelogs_read_own_or_manager" on timelogs for select
  using (user_id = auth.uid() or my_role() in ('admin','manager'));
create policy "timelogs_insert_own" on timelogs for insert
  with check (user_id = auth.uid() and my_status() = 'active');
create policy "timelogs_update_own" on timelogs for update
  using (user_id = auth.uid());

create policy "timelog_drawings_read_own_or_manager" on timelog_drawings for select
  using (exists (
    select 1 from timelogs t where t.id = timelog_id
    and (t.user_id = auth.uid() or my_role() in ('admin','manager'))
  ));
create policy "timelog_drawings_insert_own" on timelog_drawings for insert
  with check (exists (select 1 from timelogs t where t.id = timelog_id and t.user_id = auth.uid()));
