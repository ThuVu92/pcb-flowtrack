-- Purchase requests (PR) from the design department: persistent items with
-- duplicate / change / new detection across repeated uploads, plus original
-- file storage (images, PDF, Word, Excel, anything). Admin/manager only,
-- matching who can see the Purchasing tab.

create table pr_uploads (
  id uuid primary key default gen_random_uuid(),
  job_code text,
  file_name text not null,
  file_path text,
  file_type text,
  file_size bigint,
  parsed boolean not null default false,
  uploaded_by uuid references profiles(id),
  uploaded_at timestamptz not null default now(),
  new_count int not null default 0,
  dup_count int not null default 0,
  changed_count int not null default 0
);

create table pr_items (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  job_code text,
  item_name text not null,
  model text not null default '',
  maker text not null default '',
  qty_needed numeric not null default 0,
  qty_stock numeric not null default 0,
  qty_to_buy numeric not null default 0,
  unit text not null default '',
  request_date text not null default '',
  first_upload_id uuid references pr_uploads(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table pr_changes (
  id uuid primary key default gen_random_uuid(),
  upload_id uuid not null references pr_uploads(id) on delete cascade,
  item_id uuid references pr_items(id) on delete cascade,
  kind text not null check (kind in ('new','changed')),
  old jsonb,
  new jsonb,
  status text not null check (status in ('applied','pending','approved','rejected')),
  decided_by uuid references profiles(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create index pr_changes_upload_idx on pr_changes(upload_id);
create index pr_changes_status_idx on pr_changes(status);

alter table pr_uploads enable row level security;
alter table pr_items enable row level security;
alter table pr_changes enable row level security;

create policy "pr_uploads_manager" on pr_uploads for all
  using (my_role() in ('admin','manager') and my_status() = 'active')
  with check (my_role() in ('admin','manager') and my_status() = 'active');
create policy "pr_items_manager" on pr_items for all
  using (my_role() in ('admin','manager') and my_status() = 'active')
  with check (my_role() in ('admin','manager') and my_status() = 'active');
create policy "pr_changes_manager" on pr_changes for all
  using (my_role() in ('admin','manager') and my_status() = 'active')
  with check (my_role() in ('admin','manager') and my_status() = 'active');

grant select, insert, update, delete on pr_uploads, pr_items, pr_changes to authenticated;

-- Private bucket for the original PR files (25 MB each).
insert into storage.buckets (id, name, public, file_size_limit)
values ('pr-files', 'pr-files', false, 26214400)
on conflict (id) do nothing;

create policy "pr_files_manager" on storage.objects for all to authenticated
  using (bucket_id = 'pr-files' and my_role() in ('admin','manager'))
  with check (bucket_id = 'pr-files' and my_role() in ('admin','manager'));
