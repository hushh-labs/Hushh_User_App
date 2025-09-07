import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

console.log('Gmail Setup Push Notifications function started')

interface SetupPushRequest {
  userId: string
  accessToken: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    console.log('🔔 [GMAIL PUSH SETUP] Setting up push notifications')
    
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { userId, accessToken }: SetupPushRequest = await req.json()

    if (!userId || !accessToken) {
      throw new Error('Missing userId or accessToken')
    }

    // Get project details from environment
    const projectId = Deno.env.get('GOOGLE_CLOUD_PROJECT_ID')
    const topicName = Deno.env.get('GMAIL_PUBSUB_TOPIC') || 'gmail-notifications'
    
    if (!projectId) {
      throw new Error('GOOGLE_CLOUD_PROJECT_ID environment variable not set')
    }

    console.log(`🔔 [GMAIL PUSH SETUP] Setting up for user: ${userId}`)
    console.log(`🔔 [GMAIL PUSH SETUP] Project ID: ${projectId}`)
    console.log(`🔔 [GMAIL PUSH SETUP] Topic: ${topicName}`)

    // Set up Gmail push notification
    const watchRequest = {
      labelIds: ['INBOX'], // Monitor inbox messages
      topicName: `projects/${projectId}/topics/${topicName}`,
      labelFilterAction: 'include'
    }

    console.log('🔔 [GMAIL PUSH SETUP] Sending watch request to Gmail API')

    const watchResponse = await fetch(
      'https://gmail.googleapis.com/gmail/v1/users/me/watch',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(watchRequest)
      }
    )

    if (!watchResponse.ok) {
      const errorText = await watchResponse.text()
      console.error('❌ [GMAIL PUSH SETUP] Watch request failed:', errorText)
      throw new Error(`Gmail watch request failed: ${watchResponse.status} - ${errorText}`)
    }

    const watchResult = await watchResponse.json()
    console.log('✅ [GMAIL PUSH SETUP] Watch request successful:', watchResult)

    // Update the Gmail account with watch details
    const { error: updateError } = await supabase
      .from('gmail_accounts')
      .update({
        historyId: watchResult.historyId,
        updated_at: new Date().toISOString(),
        // Store watch expiration if provided
        syncSettings: {
          ...(watchResult.expiration && { watchExpiration: watchResult.expiration }),
          pushNotificationsEnabled: true,
          topicName: watchRequest.topicName
        }
      })
      .eq('userId', userId)

    if (updateError) {
      console.error('❌ [GMAIL PUSH SETUP] Error updating account:', updateError)
      throw new Error(`Failed to update account: ${updateError.message}`)
    }

    console.log('✅ [GMAIL PUSH SETUP] Push notifications setup completed')

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Push notifications setup successfully',
        historyId: watchResult.historyId,
        expiration: watchResult.expiration
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ [GMAIL PUSH SETUP] Error:', error)
    
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
