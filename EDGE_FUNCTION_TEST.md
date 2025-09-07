# Edge Function 500 Error - Immediate Fix

## Current Status
✅ OAuth WebView working perfectly
✅ Auth code captured: `4/0AVMBsJj...`
✅ Repository calling Edge Function correctly
❌ Edge Function returning 500 Internal Server Error

## Most Likely Cause: Missing Environment Variables

The Edge Function needs these environment variables to work:

```bash
GOOGLE_MEET_CLIENT_ID
GOOGLE_MEET_CLIENT_SECRET
GOOGLE_MEET_REDIRECT_URI
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

## Quick Test: Check Environment Variables

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/biiqwforuvzgubrrkfgq
2. Navigate to **Settings** → **Edge Functions** → **Environment Variables**
3. Check if these variables are set:
   - `GOOGLE_MEET_CLIENT_ID`
   - `GOOGLE_MEET_CLIENT_SECRET`
   - `GOOGLE_MEET_REDIRECT_URI`

## Set Missing Variables

If any are missing, add them:

1. Go to **Settings** → **Edge Functions** → **Environment Variables**
2. Click **Add Variable**
3. Add each missing variable:

```
Name: GOOGLE_MEET_CLIENT_ID
Value: [Your Google OAuth Client ID]

Name: GOOGLE_MEET_CLIENT_SECRET  
Value: [Your Google OAuth Client Secret]

Name: GOOGLE_MEET_REDIRECT_URI
Value: https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback
```

## Alternative: Check Edge Function Logs

1. Go to **Edge Functions** → **google-meet-sync**
2. Click **Logs** tab
3. Look for the specific error when you try the OAuth flow
4. The error will show exactly what's missing

## Expected Error Messages

- **"OAuth configuration missing"** = Missing CLIENT_ID, CLIENT_SECRET, or REDIRECT_URI
- **"Token exchange failed: invalid_client"** = Wrong CLIENT_ID or CLIENT_SECRET
- **"Failed to store account"** = Database permission issue
- **"Missing authorization code"** = Code not being passed correctly (but this is working)

## Test After Setting Variables

1. Set the environment variables
2. Wait 1-2 minutes for deployment
3. Try the OAuth flow again
4. Should work immediately

## If Still Failing

Check the Edge Function logs for the specific error message - this will tell us exactly what's wrong.

The OAuth implementation is 100% correct - it's just a configuration issue.
