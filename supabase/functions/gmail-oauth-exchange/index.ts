import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  serverAuthCode?: string
  accessToken?: string
  idToken?: string
  email: string
  userId: string
  useGoogleMeetCredentials?: boolean
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const { serverAuthCode, accessToken, idToken, email, userId, useGoogleMeetCredentials }: RequestBody = await req.json()

    console.log(`🔐 [GMAIL OAUTH] Processing OAuth exchange for user: ${userId}`)
    console.log(`🔐 [GMAIL OAUTH] Use Google Meet credentials: ${useGoogleMeetCredentials}`)

    // Validate required parameters
    if (!email || !userId) {
      throw new Error('Missing required parameters: email and userId')
    }

    // If using Google Meet credentials, we don't need serverAuthCode or accessToken
    if (!useGoogleMeetCredentials && !serverAuthCode && !accessToken) {
      throw new Error('Either serverAuthCode, accessToken, or useGoogleMeetCredentials flag is required')
    }

    // Use Google Meet OAuth configuration for unified credentials
    const GOOGLE_MEET_CLIENT_ID = Deno.env.get('GOOGLE_MEET_CLIENT_ID')!
    const GOOGLE_MEET_CLIENT_SECRET = Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')!
    
    console.log(`🔐 [GMAIL OAUTH] Using Google Meet Client ID: ${GOOGLE_MEET_CLIENT_ID?.substring(0, 20)}...`)
    console.log(`🔐 [GMAIL OAUTH] Google Meet Client Secret present: ${GOOGLE_MEET_CLIENT_SECRET ? 'Yes' : 'No'}`)
    console.log(`🔐 [GMAIL OAUTH] Full Client ID length: ${GOOGLE_MEET_CLIENT_ID?.length || 0}`)
    console.log(`🔐 [GMAIL OAUTH] Client Secret length: ${GOOGLE_MEET_CLIENT_SECRET?.length || 0}`)
    
    // Validate environment variables
    if (!GOOGLE_MEET_CLIENT_ID || GOOGLE_MEET_CLIENT_ID.length === 0) {
      throw new Error('GOOGLE_MEET_CLIENT_ID environment variable is missing or empty')
    }
    if (!GOOGLE_MEET_CLIENT_SECRET || GOOGLE_MEET_CLIENT_SECRET.length === 0) {
      throw new Error('GOOGLE_MEET_CLIENT_SECRET environment variable is missing or empty')
    }
    const GMAIL_SCOPES = [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.modify',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile'
    ]

    let tokens: any = null

    if (useGoogleMeetCredentials) {
      // Use existing Google Meet OAuth credentials
      console.log('🔐 [GMAIL OAUTH] Using Google Meet OAuth credentials')
      
      const { data: googleMeetAccount, error: meetError } = await supabase
        .from('google_meet_accounts')
        .select('access_token_encrypted, refresh_token_encrypted, email, token_expires_at')
        .eq('user_id', userId)
        .eq('is_active', true)
        .single()

      if (meetError || !googleMeetAccount) {
        throw new Error('Google Meet account not found or not connected')
      }

      console.log('✅ [GMAIL OAUTH] Found Google Meet credentials')
      
      // Check if token needs refresh
      const tokenExpiresAt = new Date(googleMeetAccount.token_expires_at)
      const now = new Date()
      
      let accessTokenToUse = googleMeetAccount.access_token_encrypted
      
      if (tokenExpiresAt <= now) {
        console.log('🔄 [GMAIL OAUTH] Google Meet token expired, refreshing...')
        
        // Refresh the token using Google Meet client credentials
        const GOOGLE_MEET_CLIENT_ID = Deno.env.get('GOOGLE_MEET_CLIENT_ID')!
        const GOOGLE_MEET_CLIENT_SECRET = Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')!
        
        const refreshResponse = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            client_id: GOOGLE_MEET_CLIENT_ID,
            client_secret: GOOGLE_MEET_CLIENT_SECRET,
            refresh_token: googleMeetAccount.refresh_token_encrypted,
            grant_type: 'refresh_token',
          }),
        })

        if (!refreshResponse.ok) {
          throw new Error('Failed to refresh Google Meet token')
        }

        const refreshData = await refreshResponse.json()
        accessTokenToUse = refreshData.access_token
        
        // Update Google Meet account with new token
        await supabase
          .from('google_meet_accounts')
          .update({
            access_token_encrypted: refreshData.access_token,
            token_expires_at: new Date(Date.now() + (refreshData.expires_in * 1000)).toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('user_id', userId)
          
        console.log('✅ [GMAIL OAUTH] Google Meet token refreshed successfully')
      }

      tokens = {
        access_token: accessTokenToUse,
        refresh_token: googleMeetAccount.refresh_token_encrypted,
        scope: GMAIL_SCOPES.join(' ')
      }
      
      console.log('✅ [GMAIL OAUTH] Using Google Meet credentials for Gmail')
    } else if (serverAuthCode) {
      // Exchange server auth code for tokens
      console.log('🔐 [GMAIL OAUTH] Using server auth code for token exchange')
      console.log('🔐 [GMAIL OAUTH] Server auth code length:', serverAuthCode.length)
      console.log('🔐 [GMAIL OAUTH] Server auth code preview:', serverAuthCode.substring(0, 20) + '...')
      
      // For mobile OAuth flows, we should NOT include redirect_uri parameter at all
      // Including an empty redirect_uri can cause "unauthorized_client" errors
      const tokenRequestParams: any = {
        code: serverAuthCode,
        client_id: GOOGLE_MEET_CLIENT_ID,
        client_secret: GOOGLE_MEET_CLIENT_SECRET,
        grant_type: 'authorization_code',
      }
      
      console.log('🔐 [GMAIL OAUTH] Token request params:', {
        code: serverAuthCode.substring(0, 20) + '...',
        client_id: GOOGLE_MEET_CLIENT_ID?.substring(0, 20) + '...',
        client_secret: GOOGLE_MEET_CLIENT_SECRET ? 'Present (' + GOOGLE_MEET_CLIENT_SECRET.length + ' chars)' : 'Missing',
        grant_type: tokenRequestParams.grant_type,
      })
      
      const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams(tokenRequestParams),
      })

      console.log('🔐 [GMAIL OAUTH] Token response status:', tokenResponse.status, tokenResponse.statusText)
      console.log('🔐 [GMAIL OAUTH] Token response headers:', Object.fromEntries(tokenResponse.headers.entries()))
      
      if (!tokenResponse.ok) {
        const error = await tokenResponse.text()
        console.error('❌ [GMAIL OAUTH] Token exchange failed with status:', tokenResponse.status)
        console.error('❌ [GMAIL OAUTH] Response body:', error)
        console.error('❌ [GMAIL OAUTH] Request was sent to:', 'https://oauth2.googleapis.com/token')
        console.error('❌ [GMAIL OAUTH] Request params used:', {
          code_length: serverAuthCode.length,
          client_id: GOOGLE_MEET_CLIENT_ID?.substring(0, 20) + '...',
          client_secret_length: GOOGLE_MEET_CLIENT_SECRET?.length,
          grant_type: tokenRequestParams.grant_type
        })
        
        // Try to parse the error for more details
        try {
          const errorObj = JSON.parse(error)
          console.error('❌ [GMAIL OAUTH] Parsed error object:', errorObj)
        } catch (e) {
          console.error('❌ [GMAIL OAUTH] Could not parse error as JSON')
        }
        
        throw new Error(`Token exchange failed: ${error}`)
      }

      tokens = await tokenResponse.json()
      console.log('✅ [GMAIL OAUTH] Token exchange successful!')
      console.log('✅ [GMAIL OAUTH] Received tokens:', {
        access_token: tokens.access_token ? 'Present (' + tokens.access_token.length + ' chars)' : 'Missing',
        refresh_token: tokens.refresh_token ? 'Present (' + tokens.refresh_token.length + ' chars)' : 'Missing',
        token_type: tokens.token_type,
        expires_in: tokens.expires_in,
        scope: tokens.scope
      })
    } else if (accessToken) {
      // Use access token directly
      console.log('🔐 [GMAIL OAUTH] Using access token directly')
      
      // Validate access token by checking user info
      const userInfoResponse = await fetch(`https://www.googleapis.com/oauth2/v2/userinfo?access_token=${accessToken}`)
      
      if (!userInfoResponse.ok) {
        throw new Error('Invalid access token')
      }

      tokens = {
        access_token: accessToken,
        refresh_token: null,
        scope: GMAIL_SCOPES.join(' ')
      }
    }

    if (!tokens) {
      throw new Error('Failed to obtain tokens from Google')
    }

    console.log('🔐 [GMAIL OAUTH] Successfully obtained tokens')

    // Prepare Gmail account data for Supabase
    const gmailAccountData = {
      userId,
      isConnected: true,
      provider: 'gmail',
      email,
      accessToken: tokens.access_token || accessToken,
      refreshToken: tokens.refresh_token || null,
      idToken: idToken || null,
      scopes: GMAIL_SCOPES,
      historyId: null,
      lastSyncAt: null,
      connectedAt: new Date().toISOString(),
      syncSettings: {},
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    // Store in Supabase gmail_accounts table
    const { error: insertError } = await supabase
      .from('gmail_accounts')
      .upsert(gmailAccountData, { onConflict: 'userId' })

    if (insertError) {
      console.error('❌ [GMAIL OAUTH] Error storing in Supabase:', insertError)
      throw new Error(`Failed to store Gmail account: ${insertError.message}`)
    }

    console.log(`✅ [GMAIL OAUTH] Gmail account connected successfully for user: ${userId}`)

    // Set up push notifications for real-time email sync
    try {
      console.log('🔔 [GMAIL OAUTH] Setting up push notifications')
      
      const pushSetupUrl = `${supabaseUrl}/functions/v1/gmail-setup-push-notifications`
      const pushResponse = await fetch(pushSetupUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabaseServiceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId,
          accessToken: tokens.access_token
        })
      })

      if (pushResponse.ok) {
        const pushResult = await pushResponse.json()
        console.log('✅ [GMAIL OAUTH] Push notifications setup successful')
      } else {
        const pushError = await pushResponse.text()
        console.warn('⚠️ [GMAIL OAUTH] Push notifications setup failed (continuing anyway):', pushError)
      }
    } catch (pushError) {
      console.warn('⚠️ [GMAIL OAUTH] Push notifications setup error (continuing anyway):', pushError)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Gmail connected successfully' 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ [GMAIL OAUTH] Error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
