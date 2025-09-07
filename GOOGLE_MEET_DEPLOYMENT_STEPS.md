# Google Meet OAuth Deployment Steps

## Current Status
✅ OAuth flow is working correctly in the app
✅ WebView is capturing auth codes successfully  
❌ Edge Function returning 500 Internal Server Error

## Required Deployment Steps

### 1. Deploy the Updated Edge Function
```bash
cd /Users/firaskola/StudioProjects/Hushh_User_App
supabase functions deploy google-meet-sync
```

### 2. Set Required Environment Variables
```bash
# Set your Google OAuth credentials
supabase secrets set GOOGLE_MEET_CLIENT_ID="your_google_client_id_here"
supabase secrets set GOOGLE_MEET_CLIENT_SECRET="your_google_client_secret_here"
supabase secrets set GOOGLE_MEET_REDIRECT_URI="https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback"
```

### 3. Run Database Migration
```bash
supabase db push
```

### 4. Verify Environment Variables
```bash
supabase secrets list
```

## Debugging Steps

### Check Edge Function Logs
```bash
supabase functions logs google-meet-sync
```

### Test Edge Function Directly
You can test the callback endpoint directly:
```bash
curl -X POST https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -d '{
    "userId": "test-user",
    "action": "callback", 
    "code": "test-code"
  }'
```

## Common Issues and Solutions

### 1. Missing Environment Variables
- Error: "OAuth configuration missing"
- Solution: Set all required secrets using `supabase secrets set`

### 2. Database Schema Mismatch
- Error: Column does not exist
- Solution: Run `supabase db push` to apply migrations

### 3. Function Not Deployed
- Error: Function returns old behavior
- Solution: Run `supabase functions deploy google-meet-sync`

### 4. CORS Issues
- Error: CORS policy blocks request
- Solution: Ensure CORS headers are properly set (already implemented)

## Expected Success Flow

1. User completes OAuth in WebView
2. WebView captures auth code: `4/0AVMBsJjI2xS8TB2spC5Iyp8il9L9QhuzLoPEwx2ceDq-DD_QTIqmTskCAfoQygMWdNBj5Q`
3. Repository calls `completeGoogleMeetOAuth` with auth code
4. Edge Function receives POST with `{"action": "callback", "code": "...", "userId": "..."}`
5. Edge Function exchanges code for tokens with Google
6. Edge Function stores account in database
7. Edge Function returns success response with account data
8. Repository returns connected account to UI
9. User sees successful connection

## Next Steps

1. Run the deployment commands above
2. Check the Edge Function logs for specific error details
3. Test the OAuth flow again
4. If still failing, check the specific error in the logs and debug accordingly
