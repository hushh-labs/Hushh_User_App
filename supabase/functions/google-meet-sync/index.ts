import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GoogleMeetSyncRequest {
  userId: string;
  accessToken?: string;
  syncType: 'full' | 'incremental';
}

interface OAuthRequest {
  userId: string;
  action: 'connect' | 'sync' | 'callback';
  code?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const pathname = url.pathname

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Handle OAuth callback
    if (pathname.includes('/callback')) {
      return handleOAuthCallback(req, supabaseClient)
    }

    // Handle OAuth initiation
    if (req.method === 'POST') {
      const body: OAuthRequest = await req.json()
      
      if (body.action === 'connect') {
        return initiateOAuthFlow(body.userId)
      } else if (body.action === 'callback') {
        return handleOAuthCallbackWithCode(body.userId, body.code!, supabaseClient)
      } else if (body.action === 'sync') {
        return handleSyncRequest(body.userId, supabaseClient)
      }
    }

    // Handle GET request for connection status
    if (req.method === 'GET') {
      const userId = url.searchParams.get('userId')
      if (!userId) {
        throw new Error('userId parameter is required')
      }
      
      return checkConnectionStatus(userId, supabaseClient)
    }

    throw new Error('Invalid request')

  } catch (error) {
    console.error('❌ Google Meet sync error:', error)
    
    // Provide more specific error information
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
    const errorDetails = {
      success: false,
      error: errorMessage,
      timestamp: new Date().toISOString(),
      path: new URL(req.url).pathname
    }
    
    return new Response(
      JSON.stringify(errorDetails),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})

function initiateOAuthFlow(userId: string) {
  const clientId = Deno.env.get('GOOGLE_MEET_CLIENT_ID')
  const redirectUri = Deno.env.get('GOOGLE_MEET_REDIRECT_URI')
  
  if (!clientId || !redirectUri) {
    throw new Error('OAuth configuration missing')
  }

const scopes = [
  'https://www.googleapis.com/auth/meetings.space.readonly',
  'https://www.googleapis.com/auth/meetings.space.created',
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/gmail.modify',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'
].join(' ')

  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
    `client_id=${clientId}&` +
    `redirect_uri=${encodeURIComponent(redirectUri)}&` +
    `response_type=code&` +
    `scope=${encodeURIComponent(scopes)}&` +
    `access_type=offline&` +
    `prompt=consent&` +
    `state=${userId}`

  return new Response(
    JSON.stringify({ 
      success: true, 
      authUrl: authUrl 
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    },
  )
}

async function handleOAuthCallbackWithCode(userId: string, code: string, supabaseClient: any) {
  console.log(`🔗 [EDGE FUNCTION] Handling OAuth callback for user: ${userId}`)

  if (!code) {
    throw new Error('Missing authorization code')
  }

  try {
    // Exchange code for tokens
    const tokenResponse = await exchangeCodeForTokens(code)
    
    // Store account information
    const accountData = await storeGoogleMeetAccount(supabaseClient, userId, tokenResponse)

    console.log(`✅ [EDGE FUNCTION] OAuth completed successfully for user: ${userId}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Google Meet account connected successfully',
        account: accountData
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error(`❌ [EDGE FUNCTION] OAuth callback error for user ${userId}:`, error)
    throw error
  }
}

async function handleOAuthCallback(req: Request, supabaseClient: any) {
  const url = new URL(req.url)
  const code = url.searchParams.get('code')
  const state = url.searchParams.get('state') // This is the userId
  const error = url.searchParams.get('error')

  if (error) {
    throw new Error(`OAuth error: ${error}`)
  }

  if (!code || !state) {
    throw new Error('Missing authorization code or state')
  }

  const userId = state

  // Exchange code for tokens
  const tokenResponse = await exchangeCodeForTokens(code)
  
  // Store account information
  await storeGoogleMeetAccount(supabaseClient, userId, tokenResponse)

  // Redirect to success page or return success response
  return new Response(
    `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Google Meet Connected</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .success { color: #4CAF50; }
        .button { background: #4285F4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }
      </style>
    </head>
    <body>
      <h1 class="success">✅ Google Meet Connected Successfully!</h1>
      <p>You can now close this window and return to the app.</p>
      <script>
        // Try to close the window (works if opened by the app)
        setTimeout(() => {
          window.close();
        }, 2000);
      </script>
    </body>
    </html>
    `,
    {
      headers: { 'Content-Type': 'text/html' },
      status: 200,
    }
  )
}

async function exchangeCodeForTokens(code: string) {
  const clientId = Deno.env.get('GOOGLE_MEET_CLIENT_ID')
  const clientSecret = Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')
  const redirectUri = Deno.env.get('GOOGLE_MEET_REDIRECT_URI')

  console.log('🔄 [TOKEN EXCHANGE] Starting token exchange...')
  console.log('🔄 [TOKEN EXCHANGE] Client ID:', clientId ? `${clientId.substring(0, 10)}...` : 'MISSING')
  console.log('🔄 [TOKEN EXCHANGE] Client Secret:', clientSecret ? 'SET' : 'MISSING')
  console.log('🔄 [TOKEN EXCHANGE] Redirect URI:', redirectUri)
  console.log('🔄 [TOKEN EXCHANGE] Auth Code:', code ? `${code.substring(0, 10)}...` : 'MISSING')

  const requestBody = new URLSearchParams({
    client_id: clientId!,
    client_secret: clientSecret!,
    code: code,
    grant_type: 'authorization_code',
    redirect_uri: redirectUri!,
  })

  console.log('🔄 [TOKEN EXCHANGE] Request body:', requestBody.toString())

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: requestBody,
  })

  console.log('🔄 [TOKEN EXCHANGE] Response status:', tokenResponse.status)
  console.log('🔄 [TOKEN EXCHANGE] Response headers:', Object.fromEntries(tokenResponse.headers.entries()))

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text()
    console.error('❌ [TOKEN EXCHANGE] Error response:', errorText)
    throw new Error(`Token exchange failed: ${tokenResponse.status} - ${errorText}`)
  }

  const tokenData = await tokenResponse.json()
  console.log('✅ [TOKEN EXCHANGE] Success! Token data keys:', Object.keys(tokenData))
  console.log('✅ [TOKEN EXCHANGE] Access token:', tokenData.access_token ? `${tokenData.access_token.substring(0, 20)}...` : 'MISSING')
  console.log('✅ [TOKEN EXCHANGE] Refresh token:', tokenData.refresh_token ? 'PRESENT' : 'MISSING')
  console.log('✅ [TOKEN EXCHANGE] Expires in:', tokenData.expires_in)
  console.log('✅ [TOKEN EXCHANGE] Token type:', tokenData.token_type)

  return tokenData
}

async function storeGoogleMeetAccount(supabaseClient: any, userId: string, tokenData: any) {
  console.log('🔍 [USER INFO] Starting user info fetch...')
  console.log('🔍 [USER INFO] Access token:', tokenData.access_token ? `${tokenData.access_token.substring(0, 20)}...` : 'MISSING')
  
  let userInfo: any;
  
  // Try primary endpoint first
  try {
    const userInfoResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: {
        'Authorization': `Bearer ${tokenData.access_token}`,
        'Accept': 'application/json',
      },
    })

    console.log('🔍 [USER INFO] Primary endpoint response status:', userInfoResponse.status)
    console.log('🔍 [USER INFO] Primary endpoint response headers:', Object.fromEntries(userInfoResponse.headers.entries()))

    if (userInfoResponse.ok) {
      userInfo = await userInfoResponse.json()
      console.log('✅ [USER INFO] Success with primary endpoint:', JSON.stringify(userInfo, null, 2))
    } else {
      const errorText = await userInfoResponse.text()
      console.error('❌ [USER INFO] Primary endpoint error:', errorText)
      throw new Error(`Primary endpoint failed: ${userInfoResponse.status}`)
    }
  } catch (primaryError) {
    console.log('🔄 [USER INFO] Primary endpoint failed, trying alternative endpoint...')
    
    // Try alternative endpoint
    try {
      const altUserInfoResponse = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: {
          'Authorization': `Bearer ${tokenData.access_token}`,
          'Accept': 'application/json',
        },
      })
      
      console.log('🔄 [USER INFO] Alternative response status:', altUserInfoResponse.status)
      
      if (altUserInfoResponse.ok) {
        userInfo = await altUserInfoResponse.json()
        console.log('✅ [USER INFO] Success with alternative endpoint:', JSON.stringify(userInfo, null, 2))
      } else {
        const altErrorText = await altUserInfoResponse.text()
        console.error('❌ [USER INFO] Alternative endpoint also failed:', altErrorText)
        throw new Error(`Both endpoints failed. Primary: ${primaryError.message}, Alternative: ${altUserInfoResponse.status} - ${altErrorText}`)
      }
    } catch (altError) {
      console.error('❌ [USER INFO] Both endpoints failed completely')
      throw new Error(`Failed to get user info from both endpoints. Primary: ${primaryError.message}, Alternative: ${altError.message}`)
    }
  }
  
  console.log('📋 [EDGE FUNCTION] User info received:', JSON.stringify(userInfo, null, 2))

  // Validate required fields
  if (!userInfo.id && !userInfo.sub) {
    throw new Error(`Missing user ID in Google response: ${JSON.stringify(userInfo)}`)
  }
  
  if (!userInfo.email) {
    throw new Error(`Missing email in Google response: ${JSON.stringify(userInfo)}`)
  }

  // Use 'sub' field if 'id' is not available (newer Google API responses use 'sub')
  const googleAccountId = userInfo.id || userInfo.sub
  
  const accountData = {
    user_id: userId,
    google_account_id: googleAccountId,
    email: userInfo.email,
    display_name: userInfo.name || userInfo.given_name || 'Unknown',
    profile_picture_url: userInfo.picture,
    access_token_encrypted: tokenData.access_token,
    refresh_token_encrypted: tokenData.refresh_token,
    token_expires_at: new Date(Date.now() + (tokenData.expires_in * 1000)).toISOString(),
    is_active: true,
    connected_at: new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }

  console.log('💾 [EDGE FUNCTION] Storing account data:', {
    user_id: accountData.user_id,
    google_account_id: accountData.google_account_id,
    email: accountData.email,
    display_name: accountData.display_name
  })

  const { error } = await supabaseClient
    .from('google_meet_accounts')
    .upsert(accountData, { onConflict: 'user_id' })

  if (error) {
    throw new Error(`Failed to store account: ${error.message}`)
  }

  console.log(`✅ Stored Google Meet account for user: ${userId}`)
  
  // Return account data without sensitive tokens for the response
  return {
    id: `${userId}_${googleAccountId}`, // Generate a consistent ID
    user_id: userId,
    google_account_id: googleAccountId,
    email: userInfo.email,
    display_name: userInfo.name || userInfo.given_name || 'Unknown',
    profile_picture_url: userInfo.picture,
    connected_at: accountData.connected_at,
    last_synced_at: null,
    is_active: true,
    access_token_encrypted: null, // Don't expose in response
    refresh_token_encrypted: null, // Don't expose in response
    token_expires_at: null, // Don't expose in response
    created_at: accountData.created_at,
    updated_at: accountData.updated_at
  }
}

async function checkConnectionStatus(userId: string, supabaseClient: any) {
  const { data, error } = await supabaseClient
    .from('google_meet_accounts')
    .select('is_active, email')
    .eq('user_id', userId)
    .eq('is_active', true)
    .single()

  if (error && error.code !== 'PGRST116') { // PGRST116 is "not found"
    throw error
  }

  const isConnected = !!data

  return new Response(
    JSON.stringify({ 
      success: true, 
      isConnected: isConnected,
      email: data?.email || null
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    },
  )
}

async function handleSyncRequest(userId: string, supabaseClient: any) {
  console.log(`🔄 [GOOGLE MEET SUPABASE] Syncing data for user: ${userId}`)
  
  try {
    // Validate environment variables first
    const clientId = Deno.env.get('GOOGLE_MEET_CLIENT_ID')
    const clientSecret = Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')
    
    if (!clientId || !clientSecret) {
      console.error('❌ [GOOGLE MEET SUPABASE] Missing environment variables')
      throw new Error('Google Meet OAuth configuration missing')
    }
    
    console.log('✅ [GOOGLE MEET SUPABASE] Environment variables validated')

    // Get stored access token
    const { data: account, error: accountError } = await supabaseClient
      .from('google_meet_accounts')
      .select('access_token_encrypted, refresh_token_encrypted, token_expires_at')
      .eq('user_id', userId)
      .eq('is_active', true)
      .single()

    if (accountError || !account) {
      console.log('❌ [GOOGLE MEET SUPABASE] Account not found or error:', accountError)
      throw new Error('Google Meet account not connected')
    }

    console.log('✅ [GOOGLE MEET SUPABASE] Account found')

    // Check if token needs refresh
    const tokenExpiresAt = new Date(account.token_expires_at)
    const now = new Date()
    const fiveMinutesFromNow = new Date(now.getTime() + 5 * 60 * 1000) // 5 minutes buffer
    
    let accessToken = account.access_token_encrypted

    if (tokenExpiresAt <= fiveMinutesFromNow) {
      console.log('🔄 [GOOGLE MEET SUPABASE] Token needs refresh')
      try {
        // Refresh the token
        accessToken = await refreshAccessToken(account.refresh_token_encrypted, supabaseClient, userId)
        console.log('✅ [GOOGLE MEET SUPABASE] Token refreshed successfully')
      } catch (refreshError) {
        console.error('❌ [GOOGLE MEET SUPABASE] Token refresh failed:', refreshError)
        throw new Error(`Token refresh failed: ${refreshError.message}`)
      }
    } else {
      console.log('✅ [GOOGLE MEET SUPABASE] Token is still valid')
    }

    // Fetch and store Google Meet data with error handling
    let meetData = { conferences: [], recordings: [], transcripts: [], participants: [] }
    try {
      console.log('📊 [GOOGLE MEET SUPABASE] Fetching Google Meet data...')
      meetData = await fetchGoogleMeetData(accessToken)
      await storeGoogleMeetData(supabaseClient, userId, meetData)
      console.log('✅ [GOOGLE MEET SUPABASE] Google Meet data synced successfully')
    } catch (meetError) {
      console.error('⚠️ [GOOGLE MEET SUPABASE] Google Meet sync failed:', meetError)
      // Continue with calendar sync even if Meet sync fails
    }

    // Fetch and store Google Calendar data with error handling
    let calendarData = { events: [], attendees: [] }
    try {
      console.log('📅 [GOOGLE MEET SUPABASE] Fetching Google Calendar data...')
      calendarData = await fetchGoogleCalendarData(accessToken)
      await storeGoogleCalendarData(supabaseClient, userId, calendarData)
      console.log('✅ [GOOGLE MEET SUPABASE] Google Calendar data synced successfully')
    } catch (calendarError) {
      console.error('⚠️ [GOOGLE MEET SUPABASE] Google Calendar sync failed:', calendarError)
      // Continue even if calendar sync fails
    }

    // Correlate calendar events with meet conferences (optional)
    try {
      await correlateCalendarWithMeetings(supabaseClient, userId)
      console.log('✅ [GOOGLE MEET SUPABASE] Calendar-Meet correlation completed')
    } catch (correlationError) {
      console.error('⚠️ [GOOGLE MEET SUPABASE] Correlation failed:', correlationError)
      // Don't fail the entire sync for correlation issues
    }

    console.log('✅ [GOOGLE MEET SUPABASE] Sync completed successfully')

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Google Meet and Calendar data synced successfully',
        syncedData: {
          conferences: meetData.conferences.length,
          recordings: meetData.recordings.length,
          transcripts: meetData.transcripts.length,
          calendarEvents: calendarData.events.length,
          attendees: calendarData.attendees.length
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('❌ [GOOGLE MEET SUPABASE] Error syncing data:', error)
    throw error
  }
}

async function refreshAccessToken(refreshToken: string, supabaseClient: any, userId: string) {
  const clientId = Deno.env.get('GOOGLE_MEET_CLIENT_ID')
  const clientSecret = Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      client_id: clientId!,
      client_secret: clientSecret!,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  })

  if (!response.ok) {
    throw new Error('Failed to refresh access token')
  }

  const tokenData = await response.json()

  // Update stored tokens
  await supabaseClient
    .from('google_meet_accounts')
    .update({
      access_token_encrypted: tokenData.access_token,
      token_expires_at: new Date(Date.now() + (tokenData.expires_in * 1000)).toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('user_id', userId)

  return tokenData.access_token
}

async function fetchGoogleMeetData(accessToken: string) {
  const baseUrl = 'https://meet.googleapis.com/v2'
  const headers = {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  }

  console.log('📊 Fetching conference records from Google Meet API...')

  // Fetch conference records
  const conferencesResponse = await fetch(
    `${baseUrl}/conferenceRecords?pageSize=50`,
    { headers }
  )

  console.log('📊 Google Meet API response status:', conferencesResponse.status)
  console.log('📊 Google Meet API response headers:', Object.fromEntries(conferencesResponse.headers.entries()))

  if (!conferencesResponse.ok) {
    const errorText = await conferencesResponse.text()
    console.error('❌ Google Meet API error response:', errorText)
    throw new Error(`Failed to fetch conferences: ${conferencesResponse.status} - ${errorText}`)
  }

  const conferencesData = await conferencesResponse.json()
  const conferences = conferencesData.conferenceRecords || []

  console.log(`📊 Found ${conferences.length} conferences`)

  // Fetch recordings and transcripts for each conference
  const recordings: any[] = []
  const transcripts: any[] = []
  const participants: any[] = []

  for (const conference of conferences) {
    const conferenceId = conference.name.split('/').pop()

    try {
      // Fetch participants
      const participantsResponse = await fetch(
        `${baseUrl}/conferenceRecords/${conferenceId}/participants`,
        { headers }
      )
      
      if (participantsResponse.ok) {
        const participantsData = await participantsResponse.json()
        participants.push(...(participantsData.participants || []))
      }

      // Fetch recordings
      const recordingsResponse = await fetch(
        `${baseUrl}/conferenceRecords/${conferenceId}/recordings`,
        { headers }
      )
      
      if (recordingsResponse.ok) {
        const recordingsData = await recordingsResponse.json()
        recordings.push(...(recordingsData.recordings || []))
      }

      // Fetch transcripts
      const transcriptsResponse = await fetch(
        `${baseUrl}/conferenceRecords/${conferenceId}/transcripts`,
        { headers }
      )
      
      if (transcriptsResponse.ok) {
        const transcriptsData = await transcriptsResponse.json()
        transcripts.push(...(transcriptsData.transcripts || []))
      }

    } catch (error) {
      console.warn(`⚠️ Error fetching data for conference ${conferenceId}:`, error)
      // Continue with other conferences
    }
  }

  console.log(`📊 Fetched ${recordings.length} recordings, ${transcripts.length} transcripts, ${participants.length} participants`)

  return {
    conferences,
    recordings,
    transcripts,
    participants
  }
}

async function storeGoogleMeetData(supabaseClient: any, userId: string, meetData: any) {
  console.log('💾 Storing Google Meet data in Supabase...')

  // Store conferences
  if (meetData.conferences.length > 0) {
    const conferencesToStore = meetData.conferences.map((conference: any) => ({
      user_id: userId,
      conference_name: conference.name,
      start_time: conference.startTime,
      end_time: conference.endTime,
      participant_count: 0, // Will be updated when storing participants
      was_recorded: meetData.recordings.some((r: any) => r.name.includes(conference.name.split('/').pop())),
      was_transcribed: meetData.transcripts.some((t: any) => t.name.includes(conference.name.split('/').pop())),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }))

    const { error: conferencesError } = await supabaseClient
      .from('google_meet_conferences')
      .upsert(conferencesToStore, { onConflict: 'user_id,conference_name' })

    if (conferencesError) {
      console.error('❌ Error storing conferences:', conferencesError)
      throw conferencesError
    }

    console.log(`✅ Stored ${conferencesToStore.length} conferences`)
  }

  // Store participants
  if (meetData.participants.length > 0) {
    const participantsToStore = meetData.participants.map((participant: any) => ({
      user_id: userId,
      conference_id: null, // Would need to map from conference name
      participant_name: participant.name,
      display_name: participant.displayName,
      email: participant.email,
      join_time: participant.earliestStartTime,
      leave_time: participant.latestEndTime,
      role: 'participant',
      created_at: new Date().toISOString()
    }))

    const { error: participantsError } = await supabaseClient
      .from('google_meet_participants')
      .upsert(participantsToStore)

    if (participantsError) {
      console.error('❌ Error storing participants:', participantsError)
      throw participantsError
    }

    console.log(`✅ Stored ${participantsToStore.length} participants`)
  }

  // Store recordings
  if (meetData.recordings.length > 0) {
    const recordingsToStore = meetData.recordings.map((recording: any) => ({
      user_id: userId,
      conference_id: null, // Would need to map from conference name
      recording_name: recording.name,
      drive_destination: recording.driveDestination,
      state: recording.state,
      start_time: recording.startTime,
      end_time: recording.endTime,
      created_at: new Date().toISOString()
    }))

    const { error: recordingsError } = await supabaseClient
      .from('google_meet_recordings')
      .upsert(recordingsToStore)

    if (recordingsError) {
      console.error('❌ Error storing recordings:', recordingsError)
      throw recordingsError
    }

    console.log(`✅ Stored ${recordingsToStore.length} recordings`)
  }

  // Store transcripts
  if (meetData.transcripts.length > 0) {
    const transcriptsToStore = meetData.transcripts.map((transcript: any) => ({
      user_id: userId,
      conference_id: null, // Would need to map from conference name
      transcript_name: transcript.name,
      drive_destination: transcript.driveDestination,
      state: transcript.state,
      start_time: transcript.startTime,
      end_time: transcript.endTime,
      created_at: new Date().toISOString()
    }))

    const { error: transcriptsError } = await supabaseClient
      .from('google_meet_transcripts')
      .upsert(transcriptsToStore)

    if (transcriptsError) {
      console.error('❌ Error storing transcripts:', transcriptsError)
      throw transcriptsError
    }

    console.log(`✅ Stored ${transcriptsToStore.length} transcripts`)
  }

  console.log('💾 Google Meet data storage completed')
}

async function fetchGoogleCalendarData(accessToken: string) {
  const baseUrl = 'https://www.googleapis.com/calendar/v3'
  const headers = {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json',
  }

  console.log('📅 Fetching calendar events from Google Calendar API...')

  // Fetch events from the last 30 days and next 60 days for PDA context
  const timeMin = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  const timeMax = new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString()

  const eventsResponse = await fetch(
    `${baseUrl}/calendars/primary/events?` +
    `timeMin=${encodeURIComponent(timeMin)}&` +
    `timeMax=${encodeURIComponent(timeMax)}&` +
    `maxResults=250&` +
    `singleEvents=true&` +
    `orderBy=startTime`,
    { headers }
  )

  if (!eventsResponse.ok) {
    throw new Error(`Failed to fetch calendar events: ${eventsResponse.status}`)
  }

  const eventsData = await eventsResponse.json()
  const events = eventsData.items || []

  console.log(`📅 Found ${events.length} calendar events`)

  // Filter events with Google Meet links and collect attendees
  const meetingEvents: any[] = []
  const allAttendees: any[] = []

  for (const event of events) {
    // Check if event has Google Meet link
    const hasMeetLink = event.hangoutLink || 
      (event.conferenceData?.entryPoints?.some((ep: any) => 
        ep.entryPointType === 'video' && ep.uri?.includes('meet.google.com')
      )) ||
      (event.description && event.description.includes('meet.google.com'))

    if (hasMeetLink) {
      meetingEvents.push(event)

      // Collect attendees for this event
      if (event.attendees) {
        for (const attendee of event.attendees) {
          allAttendees.push({
            ...attendee,
            eventId: event.id
          })
        }
      }
    }
  }

  console.log(`📅 Found ${meetingEvents.length} events with Google Meet links`)
  console.log(`👥 Found ${allAttendees.length} total attendees`)

  return {
    events: meetingEvents,
    attendees: allAttendees
  }
}

async function storeGoogleCalendarData(supabaseClient: any, userId: string, calendarData: any) {
  console.log('💾 Storing Google Calendar data in Supabase...')

  // Store calendar events
  if (calendarData.events.length > 0) {
    const eventsToStore = calendarData.events.map((event: any) => {
      // Extract Google Meet link
      let googleMeetLink = event.hangoutLink
      
      if (!googleMeetLink && event.conferenceData?.entryPoints) {
        const meetEntry = event.conferenceData.entryPoints.find((ep: any) => 
          ep.entryPointType === 'video' && ep.uri?.includes('meet.google.com')
        )
        googleMeetLink = meetEntry?.uri
      }

      if (!googleMeetLink && event.description) {
        const meetRegex = /https:\/\/meet\.google\.com\/[a-z-]+/
        const match = event.description.match(meetRegex)
        googleMeetLink = match?.[0]
      }

      // Parse start and end times
      let startTime, endTime, isAllDay = false
      
      if (event.start.date) {
        // All-day event
        startTime = event.start.date
        endTime = event.end.date
        isAllDay = true
      } else {
        // Timed event
        startTime = event.start.dateTime
        endTime = event.end.dateTime
      }

      return {
        userId: userId, // Note: using camelCase to match our schema
        google_event_id: event.id,
        calendar_id: 'primary',
        summary: event.summary || 'No Title',
        description: event.description,
        location: event.location,
        start_time: startTime,
        end_time: endTime,
        is_all_day: isAllDay,
        status: event.status || 'confirmed',
        visibility: event.visibility,
        recurrence_rule: event.recurrence?.join(','),
        google_meet_link: googleMeetLink,
        organizer_email: event.organizer?.email,
        organizer_name: event.organizer?.displayName,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    })

    const { error: eventsError } = await supabaseClient
      .from('google_calendar_events')
      .upsert(eventsToStore, { onConflict: 'userId,google_event_id' })

    if (eventsError) {
      console.error('❌ Error storing calendar events:', eventsError)
      throw eventsError
    }

    console.log(`✅ Stored ${eventsToStore.length} calendar events`)
  }

  // Store attendees
  if (calendarData.attendees.length > 0) {
    const attendeesToStore = calendarData.attendees.map((attendee: any) => ({
      userId: userId, // Note: using camelCase to match our schema
      event_id: null, // Will be updated after we get the stored event IDs
      email: attendee.email,
      display_name: attendee.displayName,
      response_status: attendee.responseStatus || 'needsAction',
      is_organizer: attendee.organizer || false,
      is_optional: attendee.optional || false,
      created_at: new Date().toISOString(),
      google_event_id: attendee.eventId // Temporary field for correlation
    }))

    // Get stored event IDs to correlate attendees
    const { data: storedEvents } = await supabaseClient
      .from('google_calendar_events')
      .select('id, google_event_id')
      .eq('userId', userId)

    const eventIdMap = new Map()
    storedEvents?.forEach((event: any) => {
      eventIdMap.set(event.google_event_id, event.id)
    })

    // Update attendees with correct event_id
    const finalAttendeesToStore = attendeesToStore
      .filter((attendee: any) => eventIdMap.has(attendee.google_event_id))
      .map((attendee: any) => ({
        ...attendee,
        event_id: eventIdMap.get(attendee.google_event_id),
        google_event_id: undefined // Remove temporary field
      }))

    if (finalAttendeesToStore.length > 0) {
      const { error: attendeesError } = await supabaseClient
        .from('google_calendar_attendees')
        .upsert(finalAttendeesToStore)

      if (attendeesError) {
        console.error('❌ Error storing calendar attendees:', attendeesError)
        throw attendeesError
      }

      console.log(`✅ Stored ${finalAttendeesToStore.length} calendar attendees`)
    }
  }

  console.log('💾 Google Calendar data storage completed')
}

async function correlateCalendarWithMeetings(supabaseClient: any, userId: string) {
  console.log('🔗 Correlating calendar events with Google Meet conferences...')

  // Get calendar events with Google Meet links
  const { data: calendarEvents } = await supabaseClient
    .from('google_calendar_events')
    .select('id, google_meet_link, start_time, end_time, summary')
    .eq('userId', userId)
    .not('google_meet_link', 'is', null)

  // Get Google Meet conferences
  const { data: meetConferences } = await supabaseClient
    .from('google_meet_conferences')
    .select('id, conference_name, start_time, end_time')
    .eq('user_id', userId)

  if (!calendarEvents || !meetConferences) {
    console.log('📊 No data to correlate')
    return
  }

  const correlations: any[] = []

  for (const calendarEvent of calendarEvents) {
    for (const meetConference of meetConferences) {
      let correlationConfidence = 0
      let correlationMethod = ''

      // Method 1: Time-based correlation (±15 minutes tolerance)
      const calendarStart = new Date(calendarEvent.start_time)
      const meetStart = new Date(meetConference.start_time)
      const timeDiff = Math.abs(calendarStart.getTime() - meetStart.getTime())
      const fifteenMinutes = 15 * 60 * 1000

      if (timeDiff <= fifteenMinutes) {
        correlationConfidence += 0.7
        correlationMethod = 'time_match'

        // Method 2: Title similarity (basic check)
        if (calendarEvent.summary && meetConference.conference_name) {
          const calendarTitle = calendarEvent.summary.toLowerCase()
          const meetTitle = meetConference.conference_name.toLowerCase()
          
          if (calendarTitle.includes('meet') || meetTitle.includes(calendarTitle.substring(0, 10))) {
            correlationConfidence += 0.2
            correlationMethod = 'time_match,title_similarity'
          }
        }

        // Only store correlations with reasonable confidence
        if (correlationConfidence >= 0.6) {
          correlations.push({
            userId: userId,
            calendar_event_id: calendarEvent.id,
            meet_conference_id: meetConference.id,
            correlation_confidence: Math.min(correlationConfidence, 1.0),
            correlation_method: correlationMethod,
            created_at: new Date().toISOString()
          })
        }
      }
    }
  }

  if (correlations.length > 0) {
    const { error: correlationError } = await supabaseClient
      .from('google_meet_calendar_links')
      .upsert(correlations, { onConflict: 'calendar_event_id,meet_conference_id' })

    if (correlationError) {
      console.error('❌ Error storing correlations:', correlationError)
      throw correlationError
    }

    console.log(`✅ Created ${correlations.length} calendar-meeting correlations`)
  } else {
    console.log('📊 No correlations found')
  }
}

/* To deploy this function:
1. Set Supabase secrets:
   - GOOGLE_MEET_CLIENT_ID
   - GOOGLE_MEET_CLIENT_SECRET  
   - GOOGLE_MEET_REDIRECT_URI
2. Run: supabase functions deploy google-meet-sync
3. Run the database migration for calendar tables
*/
