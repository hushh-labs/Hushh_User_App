#!/bin/bash

# Deploy Supabase Edge Functions for Gmail Integration
# Make sure you have the Supabase CLI installed and logged in

set -e

echo "🚀 Deploying Supabase Edge Functions for Gmail Integration..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

# Check if user is logged in
if ! supabase projects list &> /dev/null; then
    echo "❌ Not logged in to Supabase. Please run 'supabase login' first."
    exit 1
fi

echo "📦 Deploying Gmail OAuth Exchange function..."
supabase functions deploy gmail-oauth-exchange

echo "📦 Deploying Gmail Date Range Sync function..."
supabase functions deploy gmail-sync-with-date-range

echo "📦 Deploying Gmail Incremental Sync function..."
supabase functions deploy gmail-sync-incremental

echo "✅ All functions deployed successfully!"
echo ""
echo "🔧 Next steps:"
echo "1. Set up your environment variables in Supabase Dashboard > Settings > Edge Functions"
echo "2. Add the following secrets:"
echo "   - GOOGLE_CLIENT_ID"
echo "   - GOOGLE_CLIENT_SECRET"
echo "   - SUPABASE_SERVICE_ROLE_KEY"
echo "3. Update your Flutter app to use the new Edge Function URLs"
echo ""
echo "🔗 Your function URLs:"
echo "   - OAuth Exchange: https://your-project.supabase.co/functions/v1/gmail-oauth-exchange"
echo "   - Date Range Sync: https://your-project.supabase.co/functions/v1/gmail-sync-with-date-range"
echo "   - Incremental Sync: https://your-project.supabase.co/functions/v1/gmail-sync-incremental"
