-- Stage 1: Auth foundation — profiles, departments, stages
-- Apply this in the Supabase SQL Editor (Project → SQL Editor → New query).

-- ---------- Departments & stages (master data) ----------
create table depts (
  id uuid primary key default gen_random_uuid(),
  name text unique not null
);

create table stages (
  id uuid primary key default gen_random_uuid(),
  dept_id uuid references depts(id) on delete cascade,
  name text not null,
  sort_order int default 0,
  unique (dept_id, name)
);

-- ---------- Profiles (app-facing user data, 1:1 with Supabase Auth) ----------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  code text unique not null,
  username text unique not null,
  dept_id uuid references depts(id),
  role text not null check (role in ('admin','manager','employee')),
  status text not null default 'pending' check (status in ('active','pending','locked')),
  created_at timestamptz default now()
);

-- Helper functions: read the calling user's own role/status without
-- triggering RLS recursion on `profiles` (security definer bypasses RLS
-- inside the function body only, for this narrow single-column read).
create or replace function my_role() returns text
language sql security definer stable as $$
  select role from profiles where id = auth.uid()
$$;

create or replace function my_status() returns text
language sql security definer stable as $$
  select status from profiles where id = auth.uid()
$$;

-- ---------- Row Level Security ----------
alter table depts enable row level security;
alter table stages enable row level security;
alter table profiles enable row level security;

-- Dept names aren't sensitive and the signup screen (before login) needs
-- them for its dropdown, so depts are readable even by anonymous visitors.
-- Only admins can write.
create policy "depts_read_all" on depts for select
  using (true);
create policy "depts_write_admin" on depts for insert
  with check (my_role() = 'admin');
create policy "depts_update_admin" on depts for update
  using (my_role() = 'admin');
create policy "depts_delete_admin" on depts for delete
  using (my_role() = 'admin');

create policy "stages_read_all" on stages for select
  using (auth.role() = 'authenticated');
create policy "stages_write_admin" on stages for insert
  with check (my_role() = 'admin');
create policy "stages_update_admin" on stages for update
  using (my_role() = 'admin');
create policy "stages_delete_admin" on stages for delete
  using (my_role() = 'admin');

-- Profiles: any authenticated user can read the whole list — the table
-- holds no secret (passwords live in Supabase's own auth.users), and the
-- UI needs everyone's name/dept for pickers, chat authorship, and filters.
-- Only admins can approve/lock/change roles; a new user can insert their
-- own pending profile at signup time.
create policy "profiles_read_all" on profiles for select
  using (auth.role() = 'authenticated');
create policy "profiles_insert_self" on profiles for insert
  with check (id = auth.uid());
create policy "profiles_update_admin" on profiles for update
  using (my_role() = 'admin');

-- ---------- Seed data ----------
-- Seed the initial departments matching the current app's default DEPTS.
insert into depts (name) values ('Thiết kế'), ('Mua hàng'), ('Sản xuất');

-- Bootstrapping note: the very first admin account cannot self-approve
-- (approveUser() requires an existing admin). After creating the first
-- user through the app's signup screen, find their id in
-- Authentication → Users, then run:
--   update profiles set role = 'admin', status = 'active' where id = '<uuid>';
