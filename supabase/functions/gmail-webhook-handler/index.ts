import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

console.log('Gmail Webhook Handler function started')

interface PubSubMessage {
  message: {
    data: string
    messageId: string
    publishTime: string
  }
  subscription: string
}

interface GmailNotification {
  emailAddress: string
  historyId: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('🔔 [GMAIL WEBHOOK] Received webhook request')
    
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse the Pub/Sub message
    const body = await req.json() as PubSubMessage
    
    if (!body.message || !body.message.data) {
      console.log('❌ [GMAIL WEBHOOK] No message data found')
      return new Response('No message data', { status: 400 })
    }

    // Decode the base64 message data
    const decodedData = atob(body.message.data)
    const notification: GmailNotification = JSON.parse(decodedData)
    
    console.log(`🔔 [GMAIL WEBHOOK] Notification for: ${notification.emailAddress}`)
    console.log(`🔔 [GMAIL WEBHOOK] History ID: ${notification.historyId}`)

    // Find the user account for this email
    const { data: gmailAccount, error: accountError } = await supabase
      .from('gmail_accounts')
      .select('userId, email, historyId')
      .eq('email', notification.emailAddress)
      .eq('isConnected', true)
      .single()

    if (accountError || !gmailAccount) {
      console.log(`❌ [GMAIL WEBHOOK] No connected account found for: ${notification.emailAddress}`)
      return new Response('Account not found', { status: 404 })
    }

    console.log(`🔔 [GMAIL WEBHOOK] Found account for user: ${gmailAccount.userId}`)

    // Check if this is a new notification (history ID should be newer)
    const currentHistoryId = gmailAccount.historyId
    const newHistoryId = notification.historyId

    if (currentHistoryId && parseInt(newHistoryId) <= parseInt(currentHistoryId)) {
      console.log(`🔔 [GMAIL WEBHOOK] History ID not newer, skipping (current: ${currentHistoryId}, new: ${newHistoryId})`)
      return new Response('History ID not newer', { status: 200 })
    }

    // Trigger incremental sync for this user
    console.log(`🚀 [GMAIL WEBHOOK] Triggering incremental sync for user: ${gmailAccount.userId}`)
    
    // Call the existing incremental sync function
    const incrementalSyncUrl = `${supabaseUrl}/functions/v1/gmail-sync-incremental`
    const syncResponse = await fetch(incrementalSyncUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${supabaseServiceKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: gmailAccount.userId,
        trigger: 'webhook'
      })
    })

    if (!syncResponse.ok) {
      const errorText = await syncResponse.text()
      console.error(`❌ [GMAIL WEBHOOK] Sync failed: ${errorText}`)
      throw new Error(`Incremental sync failed: ${errorText}`)
    }

    const syncResult = await syncResponse.json()
    console.log(`✅ [GMAIL WEBHOOK] Sync completed:`, syncResult)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Webhook processed successfully',
        userId: gmailAccount.userId,
        emailAddress: notification.emailAddress,
        syncResult
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ [GMAIL WEBHOOK] Error processing webhook:', error)
    
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
