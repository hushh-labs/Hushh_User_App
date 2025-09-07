# Supabase Edge Functions for Gmail Integration

This directory contains Supabase Edge Functions that replace Firebase Cloud Functions for Gmail integration with the Hushh User App.

## Functions Overview

### 1. `gmail-oauth-exchange`
Handles Gmail OAuth token exchange from Google Sign-In credentials.

**Endpoint:** `https://your-project.supabase.co/functions/v1/gmail-oauth-exchange`

**Request Body:**
```json
{
  "serverAuthCode": "optional_server_auth_code",
  "accessToken": "required_access_token",
  "idToken": "optional_id_token",
  "email": "user@example.com",
  "userId": "firebase_user_id"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Gmail connected successfully"
}
```

### 2. `gmail-sync-with-date-range`
Syncs Gmail emails within a specified date range.

**Endpoint:** `https://your-project.supabase.co/functions/v1/gmail-sync-with-date-range`

**Request Body:**
```json
{
  "userId": "firebase_user_id",
  "startDate": "2024-01-01T00:00:00Z",
  "endDate": "2024-01-31T23:59:59Z",
  "syncSettings": {
    "duration": "oneMonth",
    "durationDays": 30
  }
}
```

**Response:**
```json
{
  "success": true,
  "messagesCount": 150,
  "message": "Gmail sync completed successfully"
}
```

### 3. `gmail-sync-incremental`
Performs incremental sync for new emails since last sync.

**Endpoint:** `https://your-project.supabase.co/functions/v1/gmail-sync-incremental`

**Request Body:**
```json
{
  "userId": "firebase_user_id"
}
```

**Response:**
```json
{
  "success": true,
  "newMessagesCount": 5,
  "totalMessagesCount": 155,
  "message": "Incremental Gmail sync completed successfully"
}
```

## Setup Instructions

### 1. Prerequisites
- Supabase CLI installed: `npm install -g supabase`
- Supabase project created
- Gmail tables created in Supabase (run the SQL from `../hushh_user_app/lib/features/pda/data/sql/`)

### 2. Environment Variables
Set these in your Supabase Dashboard > Settings > Edge Functions:

```bash
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GOOGLE_CLIENT_ID=your_google_oauth_client_id
GOOGLE_CLIENT_SECRET=your_google_oauth_client_secret
```

### 3. Database Setup
First, run the SQL scripts in this order:
1. `../hushh_user_app/lib/features/auth/data/sql/create_hush_users_table.sql`
2. `../hushh_user_app/lib/features/pda/data/sql/create_gmail_tables.sql`

### 4. Deploy Functions
```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Deploy all functions
./functions/deploy.sh
```

Or deploy individually:
```bash
supabase functions deploy gmail-oauth-exchange
supabase functions deploy gmail-sync-with-date-range  
supabase functions deploy gmail-sync-incremental
```

### 5. Test Functions
Use the Supabase Dashboard > Edge Functions to test each function with sample payloads.

## Security Notes

1. **Authentication**: Functions expect Firebase user authentication
2. **CORS**: Configured to allow requests from your app domain
3. **Rate Limiting**: Consider implementing rate limiting for production
4. **Token Security**: OAuth tokens are stored in Supabase with appropriate access controls

## Monitoring

- View function logs in Supabase Dashboard > Edge Functions > Logs
- Monitor database activity in Supabase Dashboard > Database > Logs
- Set up alerts for function errors

## Migration from Firebase Cloud Functions

The Flutter app has been updated to call these Edge Functions instead of Firebase Cloud Functions:

- `exchangeGoogleAuthCode` → `gmail-oauth-exchange`
- `syncGmailWithDateRange` → `gmail-sync-with-date-range`
- `syncGmailIncremental` → `gmail-sync-incremental`

The old Firebase Cloud Functions remain untouched and can be safely removed once you verify the Edge Functions are working correctly.

## Troubleshooting

### Common Issues

1. **Function deployment fails**
   - Check Supabase CLI version: `supabase --version`
   - Verify project linking: `supabase projects list`

2. **OAuth exchange fails**
   - Verify Google OAuth credentials
   - Check CORS configuration
   - Ensure proper scopes in Google Console

3. **Email sync fails**
   - Verify Gmail API is enabled in Google Console
   - Check access token validity
   - Ensure Supabase tables exist

4. **Database connection errors**
   - Verify service role key permissions
   - Check table names and column mappings
   - Ensure foreign key constraints are satisfied

For more help, check the Supabase documentation or contact support.
