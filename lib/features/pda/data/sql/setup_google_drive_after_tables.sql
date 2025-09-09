-- Run this AFTER create_drive_tables.sql
-- Idempotent bootstrap for Google Drive OAuth account + indexes/permissions

-- 1) OAuth account storage (used by google-drive-sync function)
create table if not exists public.google_drive_accounts (
  user_id varchar primary key,
  email text,
  display_name text,
  profile_picture_url text,
  access_token text,
  refresh_token text,
  token_type text,
  expires_in integer,
  scope text,
  is_active boolean default true,
  connected_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists google_drive_accounts_user_idx
  on public.google_drive_accounts (user_id);

alter table public.google_drive_accounts disable row level security;

-- 2) Helpful indexes for DriveFile (created in create_drive_tables.sql)
create index if not exists drivefile_user_id_idx on public."DriveFile"(user_id);
create index if not exists drivefile_modified_time_idx on public."DriveFile"(modified_time);
alter table public."DriveFile" disable row level security;

-- 3) Optional quick views
create or replace view public.v_drive_account_status as
select user_id, email, is_active, connected_at, updated_at
from public.google_drive_accounts;

create or replace view public.v_drive_files_by_user as
select user_id, count(*) as files, max(modified_time) as last_modified
from public."DriveFile"
group by user_id;


