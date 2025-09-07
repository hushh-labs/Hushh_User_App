# Fix Gmail 403 "Insufficient Authentication Scopes" Error

## What You Need to Do

The 403 error occurs because your Google Cloud Console OAuth application doesn't have Gmail scopes configured. Here's exactly what you need to do:

## Step 1: Add Gmail Scopes to Google Cloud Console

1. **Go to Google Cloud Console**
   - Open https://console.cloud.google.com
   - Navigate to **APIs & Services** > **Credentials**

2. **Select Your OAuth 2.0 Client ID**
   - Find your existing OAuth 2.0 Client ID (the one used for Google Meet)
   - Click on it to edit

3. **Add Gmail Scopes**
   Add these scopes to your OAuth application:
   ```
   https://www.googleapis.com/auth/gmail.readonly
   https://www.googleapis.com/auth/gmail.modify
   https://www.googleapis.com/auth/userinfo.email
   https://www.googleapis.com/auth/userinfo.profile
   ```

4. **Keep Existing Google Meet Scopes**
   Make sure these are still present:
   ```
   https://www.googleapis.com/auth/meetings.space.readonly
   https://www.googleapis.com/auth/meetings.space.created
   https://www.googleapis.com/auth/calendar.readonly
   ```

5. **Add Authorized Redirect URIs** (if not already added)
   ```
   https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/google-meet-sync/callback
   https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/gmail-oauth-exchange/callback
   ```

6. **Add Authorized JavaScript Origins** (if not already added)
   ```
   https://biiqwforuvzgubrrkfgq.supabase.co
   ```

7. **Save Configuration**
   - Click **Save**
   - Wait 5-10 minutes for changes to propagate

## Step 2: Enable Gmail API

1. **Go to APIs & Services > Library**
2. **Search for "Gmail API"**
3. **Click "Enable"** if not already enabled

## Step 3: Re-authenticate in Your App

**CRITICAL**: You must get a new access token with the Gmail scopes.

1. **Disconnect Google Meet** in your app
   - Go to your app's Google Meet settings
   - Disconnect/logout from Google Meet

2. **Reconnect Google Meet**
   - Click "Connect Google Meet" again
   - You should now see a consent screen requesting both Google Meet AND Gmail permissions
   - Accept all permissions

3. **Verify New Token Has Gmail Scopes**
   - The new access token will include Gmail scopes
   - Gmail sync should now work without 403 errors

## Step 4: Test Gmail Sync

1. **Try Gmail sync again**
   - The 403 error should be resolved
   - Gmail should now use the same OAuth credentials as Google Meet

## What We've Done

✅ **Updated Google Meet OAuth function** to request Gmail scopes
✅ **Modified Gmail repository** to use Google Meet credentials
✅ **Updated Gmail OAuth exchange** to use Google Meet client credentials
✅ **Deployed the changes** to your Supabase Edge Functions

## Why This Works

- **Unified OAuth**: One Google Cloud OAuth application for both services
- **Shared Credentials**: Gmail automatically uses Google Meet's access token
- **Single Consent**: Users only need to authenticate once for both services
- **Automatic Token Refresh**: Both services use the same refresh token

## Troubleshooting

If you still get 403 errors after following these steps:

1. **Check scope configuration** in Google Cloud Console
2. **Ensure Gmail API is enabled**
3. **Wait 10 minutes** after making changes
4. **Clear browser cache** and try again
5. **Verify you re-authenticated** and got a new token

## Expected Result

After completing these steps:
- ✅ Google Meet OAuth will request Gmail scopes
- ✅ Gmail will automatically use Google Meet credentials
- ✅ No more 403 "insufficient authentication scopes" errors
- ✅ Single OAuth flow for both Google Meet and Gmail

The error you're seeing will be completely resolved once you add the Gmail scopes to your Google Cloud Console OAuth application and re-authenticate.
