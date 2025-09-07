# Debug Edge Function 500 Error

Since the database tables already exist, the 500 error is likely caused by one of these issues:

## 1. Check Environment Variables

The Edge Function needs these environment variables set:
- `GOOGLE_MEET_CLIENT_ID`
- `GOOGLE_MEET_CLIENT_SECRET`
- `GOOGLE_MEET_REDIRECT_URI`

**Check if they're set:**
```bash
supabase secrets list
```

**Set them if missing:**
```bash
supabase secrets set GOOGLE_MEET_CLIENT_ID="your_google_client_id"
supabase secrets set GOOGLE_MEET_CLIENT_SECRET="your_google_client_secret"
supabase secrets set GOOGLE_MEET_REDIRECT_URI="https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback"
```

## 2. Check Edge Function Logs

View the actual error from the Edge Function:
```bash
supabase functions logs google-meet-sync --follow
```

Or check logs in Supabase Dashboard:
1. Go to your project dashboard
2. Navigate to **Edge Functions** → **google-meet-sync**
3. Click on **Logs** tab
4. Look for the specific error when the OAuth callback is called

## 3. Test Edge Function Directly

Test the callback endpoint with a simple request:

```bash
curl -X POST https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -d '{
    "userId": "test-user-123",
    "action": "callback",
    "code": "test-auth-code"
  }'
```

This should return a specific error message that will help identify the issue.

## 4. Common Issues and Solutions

### Missing Google OAuth Credentials
**Error:** "OAuth configuration missing"
**Solution:** Set the environment variables above

### Invalid Google Client Credentials
**Error:** "Token exchange failed: invalid_client"
**Solution:** Verify your Google OAuth client ID and secret are correct

### Wrong Redirect URI
**Error:** "Token exchange failed: redirect_uri_mismatch"
**Solution:** Ensure the redirect URI in Google Console matches exactly:
`https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback`

### Database Permission Issues
**Error:** "Failed to store account: permission denied"
**Solution:** Check if the service role key has proper permissions

### Invalid Auth Code
**Error:** "Token exchange failed: invalid_grant"
**Solution:** This happens if the auth code is expired or already used (normal for testing)

## 5. Quick Debug Steps

1. **Check the Edge Function logs** - this will show the exact error
2. **Verify environment variables are set**
3. **Test with a fresh OAuth flow** (don't reuse old auth codes)
4. **Check Google Cloud Console** - ensure OAuth consent screen is configured

## 6. Expected Success Response

When working correctly, the Edge Function should return:
```json
{
  "success": true,
  "message": "Google Meet account connected successfully",
  "account": {
    "user_id": "8yalh8RyE2Q2SS5ddavfifzVS6W2",
    "google_account_id": "...",
    "email": "user@example.com",
    "name": "User Name",
    "is_connected": true,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

The most important step is **checking the Edge Function logs** to see the exact error message.
