# Database Migration Instructions

## The Issue
The Edge Function is deployed but returning 500 errors because the database tables don't exist yet. The migration file `supabase/migrations/20250107_google_meet_integration.sql` needs to be applied to create the required tables.

## Option 1: Run Migration via Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard: https://supabase.com/dashboard/project/biiqwforuvzgubrrkfgq
2. Navigate to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste the entire contents of `supabase/migrations/20250107_google_meet_integration.sql`
5. Click **Run** to execute the migration

## Option 2: Install Supabase CLI and Run Migration

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref biiqwforuvzgubrrkfgq

# Run the migration
supabase db push
```

## Option 3: Manual Table Creation

If you prefer to create tables manually, run this SQL in your Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create google_meet_accounts table
CREATE TABLE IF NOT EXISTS google_meet_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id VARCHAR NOT NULL,
  google_account_id TEXT NOT NULL,
  email TEXT NOT NULL,
  display_name TEXT,
  profile_picture_url TEXT,
  connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_synced_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  access_token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  token_expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create other required tables (conferences, participants, etc.)
-- See the full migration file for complete schema
```

## Verification

After running the migration, you can verify the tables exist by running this query in SQL Editor:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'google_meet%';
```

You should see:
- google_meet_accounts
- google_meet_spaces  
- google_meet_conferences
- google_meet_participants
- google_meet_recordings
- google_meet_transcripts

## Test the OAuth Flow Again

Once the database migration is complete:

1. Try the Google Meet OAuth flow in your app again
2. The 500 error should be resolved
3. Check the Edge Function logs to confirm successful account creation
4. Verify the account was stored in the `google_meet_accounts` table

## Expected Success

After migration, the OAuth flow should complete successfully and you should see the account data stored in your database.
