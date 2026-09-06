-- Adds more default departments, lets anyone (including a brand-new
-- signup, pre-approval) create a custom department by name at registration,
-- and adds a table for users to send account-edit requests to Admin.

-- ---------- More default departments ----------
insert into depts (name)
select v from (values ('Admin'), ('HCNS'), ('Kho')) as t(v)
where not exists (select 1 from depts where name = t.v);

-- ---------- Allow self-service dept creation at signup ----------
-- Registration lets a user type a custom department name if none of the
-- listed ones fit. The signup flow inserts the profile row itself (see
-- profiles_insert_self), so dept creation needs to work for a user who
-- isn't approved (or even fully a "profile" yet) at that moment too.
drop policy if exists "depts_write_admin" on depts;
create policy "depts_write_admin" on depts for insert
  with check (auth.role() = 'authenticated');

-- ---------- Account edit requests (user -> Admin) ----------
create table edit_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  message text not null,
  status text not null default 'pending' check (status in ('pending','done')),
  created_at timestamptz default now()
);

alter table edit_requests enable row level security;

create policy "edit_requests_read_own_or_admin" on edit_requests for select
  using (user_id = auth.uid() or my_role() = 'admin');
create policy "edit_requests_insert_own" on edit_requests for insert
  with check (user_id = auth.uid());
create policy "edit_requests_update_admin" on edit_requests for update
  using (my_role() = 'admin');

grant select, insert, update on edit_requests to authenticated;
