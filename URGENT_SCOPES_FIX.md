# 🚨 URGENT: Fix Gmail 403 Error - Scopes Configuration Required

## The Problem
Your Gmail sync is failing with 403 "insufficient authentication scopes" because your Google Cloud Console OAuth application doesn't have Gmail scopes configured.

## ✅ What's Already Done
- ✅ Updated Google Meet OAuth function to request Gmail scopes
- ✅ Updated Gmail sync function to use Google Meet credentials  
- ✅ Deployed both functions to Supabase

## 🔥 CRITICAL STEPS YOU MUST DO NOW:

### Step 1: Add Gmail Scopes to Google Cloud Console
1. Go to https://console.cloud.google.com
2. Navigate to **APIs & Services** > **Credentials**
3. Find your OAuth 2.0 Client ID (the one used for Google Meet)
4. Click to edit it
5. Add these scopes:
   ```
   https://www.googleapis.com/auth/gmail.readonly
   https://www.googleapis.com/auth/gmail.modify
   https://www.googleapis.com/auth/userinfo.email
   https://www.googleapis.com/auth/userinfo.profile
   ```
6. Keep existing Google Meet scopes:
   ```
   https://www.googleapis.com/auth/meetings.space.readonly
   https://www.googleapis.com/auth/meetings.space.created
   https://www.googleapis.com/auth/calendar.readonly
   ```
7. **SAVE** the configuration

### Step 2: Enable Gmail API
1. Go to **APIs & Services** > **Library**
2. Search for "Gmail API"
3. Click **Enable**

### Step 3: Re-authenticate (CRITICAL!)
**Your current access token doesn't have Gmail scopes!**

1. **Disconnect Google Meet** in your app
2. **Reconnect Google Meet** - this will now request Gmail scopes too
3. **Accept all permissions** in the consent screen

## Why This Will Fix the 403 Error

The 403 error happens because:
- Your current access token was created BEFORE Gmail scopes were added
- It only has Google Meet scopes, not Gmail scopes
- Gmail API rejects requests without proper scopes

After you:
1. Add Gmail scopes to Google Cloud Console
2. Re-authenticate to get a new token with Gmail scopes

The Gmail sync will work because:
- New access token will include Gmail scopes
- Gmail sync function now uses Google Meet credentials
- Single OAuth flow for both services

## Expected Result
✅ No more 403 errors
✅ Gmail sync works using Google Meet credentials
✅ Single authentication for both Google Meet and Gmail

**The code is ready - you just need to configure the scopes and re-authenticate!**
