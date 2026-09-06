-- Enables Supabase Realtime (live push updates over websocket) for the
-- tables the app now subscribes to, so changes from one user appear for
-- everyone else without a manual page refresh. Postgres Realtime only
-- broadcasts changes for tables explicitly added to this publication;
-- RLS still applies on top (a client only receives events for rows its
-- own policies allow it to SELECT).
alter publication supabase_realtime add table
  depts, stages, profiles, jobs, drawings, drawing_versions,
  assigns, assign_comments, assign_last_seen, timelogs, timelog_drawings,
  notifs, edit_requests;
