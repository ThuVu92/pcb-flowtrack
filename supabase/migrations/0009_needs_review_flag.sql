-- Job/Drawing entries typed as free text in "Thêm tác vụ" get auto-created
-- in Master immediately (so the employee isn't blocked waiting for
-- approval), but that also means typos/near-duplicates can slip in
-- unnoticed (e.g. "Han" vs "Hàn" as two different Job codes). This flag
-- lets an admin/manager see, in one place, exactly which Master entries
-- were auto-created and haven't been reviewed yet, without blocking
-- anyone in the moment they were created.
alter table jobs add column if not exists needs_review boolean not null default false;
alter table drawings add column if not exists needs_review boolean not null default false;
