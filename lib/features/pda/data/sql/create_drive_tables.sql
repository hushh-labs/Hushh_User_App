-- =========================================================
-- Google Drive unified setup (safe to run multiple times)
-- - Drops old lowercased legacy table
-- - Creates Drive OAuth account table used by edge function
-- - Creates DriveFile metadata table (expected by app/function)
-- - Adds helpful indexes
-- - Disables RLS for ingestion simplicity
-- =========================================================

-- 0) Extensions (for gen_random_uuid)
create extension if not exists pgcrypto with schema extensions;

-- 1) Drop legacy lowercased table if present
drop table if exists public.drivefile cascade;

-- 2) OAuth account storage (edge function upserts here)
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

-- 3) Files metadata table
create table if not exists public."DriveFile" (
  id uuid primary key default gen_random_uuid(),
  file_id text unique not null,
  user_id varchar not null references public.hush_users("userId") on delete cascade,
  name text,
  mime_type text,
  size bigint,
  created_time timestamp,
  modified_time timestamp,
  shared boolean,
  web_view_link text,
  thumbnail_link text,
  trashed boolean default false,
  inserted_at timestamp default now()
);

-- Helpful indexes
create index if not exists drivefile_user_id_idx on public."DriveFile"(user_id);
create index if not exists drivefile_modified_time_idx on public."DriveFile"(modified_time);

alter table public."DriveFile" disable row level security;

-- 4) Optional helper views (for quick verification)
create or replace view public.v_drive_account_status as
select user_id, email, is_active, connected_at, updated_at
from public.google_drive_accounts;

create or replace view public.v_drive_files_by_user as
select user_id, count(*) as files, max(modified_time) as last_modified
from public."DriveFile"
group by user_id;