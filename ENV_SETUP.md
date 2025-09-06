# Environment Setup for Vault Upload

## Required Environment Variables

Add these to your `.env` file:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

## How to Get Your Supabase Service Role Key

1. Go to your Supabase Dashboard
2. Navigate to **Settings** → **API**
3. Copy the **service_role** key (not the anon key)
4. Add it to your `.env` file as `SUPABASE_SERVICE_ROLE_KEY`

## Important Notes

- The **service_role** key has full access to your database and storage
- Keep it secure and never commit it to version control
- This key bypasses RLS policies, which is why we need it for storage operations

## After Adding the Key

1. Restart your Flutter app
2. Try uploading a document again
3. The 403 Unauthorized error should be resolved
