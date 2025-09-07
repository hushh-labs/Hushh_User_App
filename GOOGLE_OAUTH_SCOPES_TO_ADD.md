# Gmail Scopes to Add to Google Cloud Console

## Problem
You're getting a 403 "insufficient authentication scopes" error because your Google Meet OAuth application doesn't have Gmail scopes configured.

## Required Gmail Scopes

Add these scopes to your Google Cloud Console OAuth application:

### Essential Gmail Scopes
```
https://www.googleapis.com/auth/gmail.readonly
https://www.googleapis.com/auth/gmail.modify
https://www.googleapis.com/auth/userinfo.email
https://www.googleapis.com/auth/userinfo.profile
```

### Current Google Meet Scopes (keep these)
```
https://www.googleapis.com/auth/meetings.space.readonly
https://www.googleapis.com/auth/meetings.space.created
https://www.googleapis.com/auth/calendar.readonly
```

## How to Add Scopes in Google Cloud Console

1. **Go to Google Cloud Console**
   - Navigate to APIs & Services > Credentials
   - Select your OAuth 2.0 Client ID

2. **Find the Scopes Section**
   - Look for "Scopes" or "OAuth scopes"
   - Click "Add Scope" or "Edit Scopes"

3. **Add Gmail Scopes**
   - Add each Gmail scope listed above
   - Keep your existing Google Meet scopes

4. **Save Configuration**
   - Click "Save" or "Update"
   - Changes may take a few minutes to propagate

## What Each Scope Does

- `gmail.readonly`: Read Gmail messages and metadata
- `gmail.modify`: Modify Gmail messages (mark as read, etc.)
- `userinfo.email`: Access user's email address
- `userinfo.profile`: Access user's basic profile info

## After Adding Scopes

**IMPORTANT**: You must re-authenticate to get a new access token with the Gmail scopes.

1. **Disconnect Google Meet** in your app
2. **Reconnect Google Meet** - this will now request Gmail scopes too
3. **Test Gmail sync** - should work without 403 errors

## Alternative: Enable Gmail API

Also ensure Gmail API is enabled in Google Cloud Console:
1. Go to APIs & Services > Library
2. Search for "Gmail API"
3. Click "Enable" if not already enabled

## Verification

After re-authentication, your access token should include all scopes:
- Google Meet scopes (existing)
- Gmail scopes (newly added)
- User info scopes (for profile data)

This unified approach means one OAuth flow grants access to both Google Meet and Gmail.
