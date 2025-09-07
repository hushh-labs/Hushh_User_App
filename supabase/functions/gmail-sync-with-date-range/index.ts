import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  userId: string
  startDate: string
  endDate: string
  syncSettings: any
}

interface GmailMessage {
  id: string
  threadId: string
  historyId: string
  payload: any
  snippet: string
  internalDate: string
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
    const { userId, startDate, endDate, syncSettings }: RequestBody = await req.json()

    console.log(`🔄 [GMAIL SYNC] Starting date range sync for user: ${userId}`)
    console.log(`🔄 [GMAIL SYNC] Date range: ${startDate} to ${endDate}`)

    // Get Google Meet account (which now includes Gmail scopes) from Supabase
    const { data: googleMeetAccount, error: accountError } = await supabase
      .from('google_meet_accounts')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .single()

    if (accountError || !googleMeetAccount) {
      console.error('❌ [GMAIL SYNC] Google Meet account not found:', accountError)
      throw new Error('Google Meet account not found or not connected. Please connect Google Meet first to enable Gmail sync.')
    }

    // Setup Gmail API client using Google Meet credentials
    const accessToken = googleMeetAccount.access_token_encrypted
    const refreshToken = googleMeetAccount.refresh_token_encrypted

    if (!accessToken && !refreshToken) {
      throw new Error('No valid tokens found for Gmail API access. Please reconnect Google Meet.')
    }

    console.log(`✅ [GMAIL SYNC] Using Google Meet credentials for Gmail API access`)

    // Helper function to refresh access token if needed
    async function refreshAccessTokenIfNeeded() {
      const tokenExpiresAt = new Date(googleMeetAccount.token_expires_at)
      const now = new Date()
      
      if (tokenExpiresAt <= now) {
        console.log('🔄 [GMAIL SYNC] Access token expired, refreshing...')
        
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
          throw new Error('Failed to refresh access token. Please reconnect Google Meet.')
        }

        const tokenData = await response.json()

        // Update stored tokens
        await supabase
          .from('google_meet_accounts')
          .update({
            access_token_encrypted: tokenData.access_token,
            token_expires_at: new Date(Date.now() + (tokenData.expires_in * 1000)).toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('user_id', userId)

        console.log('✅ [GMAIL SYNC] Access token refreshed successfully')
        return tokenData.access_token
      }
      
      return accessToken
    }

    // Get fresh access token
    const currentAccessToken = await refreshAccessTokenIfNeeded()

    // Helper function to make Gmail API requests with rate limiting
    async function makeGmailRequest(url: string, token: string, retryCount = 0) {
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        const errorText = await response.text()
        
        // Handle rate limiting with exponential backoff
        if (response.status === 429 && retryCount < 3) {
          const delay = Math.pow(2, retryCount) * 1000 // 1s, 2s, 4s
          console.log(`⚠️ [GMAIL SYNC] Rate limited, retrying in ${delay}ms (attempt ${retryCount + 1})`)
          await new Promise(resolve => setTimeout(resolve, delay))
          return makeGmailRequest(url, token, retryCount + 1)
        }
        
        throw new Error(`Gmail API error: ${response.status} - ${errorText}`)
      }

      return response.json()
    }

    // Helper function to process requests in batches
    async function processBatch<T>(items: T[], batchSize: number, processor: (item: T) => Promise<any>) {
      const results = []
      
      for (let i = 0; i < items.length; i += batchSize) {
        const batch = items.slice(i, i + batchSize)
        
        // Process batch sequentially to avoid rate limits
        const batchResults = []
        for (const item of batch) {
          try {
            const result = await processor(item)
            batchResults.push(result)
            // Small delay between requests to respect rate limits
            await new Promise(resolve => setTimeout(resolve, 100))
          } catch (error) {
            console.error(`❌ [GMAIL SYNC] Error processing item:`, error)
            // Continue with other items even if one fails
          }
        }
        
        results.push(...batchResults)
        
        // Longer delay between batches
        if (i + batchSize < items.length) {
          await new Promise(resolve => setTimeout(resolve, 500))
        }
      }
      
      return results
    }

    // Convert date strings to timestamps for Gmail API
    const startTimestamp = Math.floor(new Date(startDate).getTime() / 1000)
    const endTimestamp = Math.floor(new Date(endDate).getTime() / 1000)

    console.log(`🔄 [GMAIL SYNC] Searching emails between ${startTimestamp} and ${endTimestamp}`)

    // Build Gmail search query
    const searchQuery = `after:${startTimestamp} before:${endTimestamp}`
    
    // Search for messages in the date range
    let allMessages: GmailMessage[] = []
    let nextPageToken = ''

    do {
      const searchUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${encodeURIComponent(searchQuery)}&maxResults=100${nextPageToken ? `&pageToken=${nextPageToken}` : ''}`
      
      const searchResult = await makeGmailRequest(searchUrl, currentAccessToken)
      
      if (searchResult.messages) {
        // Get full message details for each message using batch processing
        const messages = await processBatch(
          searchResult.messages,
          5, // Process 5 messages at a time
          async (msg: any) => {
            const messageUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}`
            return makeGmailRequest(messageUrl, currentAccessToken)
          }
        )
        
        allMessages = allMessages.concat(messages)
      }

      nextPageToken = searchResult.nextPageToken
    } while (nextPageToken)

    console.log(`🔄 [GMAIL SYNC] Found ${allMessages.length} messages to sync`)

    // Check for existing emails to avoid duplicates
    const messageIds = allMessages.map(msg => msg.id)
    const { data: existingEmails } = await supabase
      .from('gmail_emails')
      .select('messageId')
      .eq('userId', userId)
      .in('messageId', messageIds)

    const existingMessageIds = new Set(existingEmails?.map(email => email.messageId) || [])
    const newMessages = allMessages.filter(msg => !existingMessageIds.has(msg.id))
    
    console.log(`🔄 [GMAIL SYNC] ${existingMessageIds.size} emails already exist, syncing ${newMessages.length} new emails`)

    // Process and store messages in Supabase
    const emailsToInsert = newMessages.map(message => {
      const headers = message.payload?.headers || []
      const getHeader = (name: string) => headers.find((h: any) => h.name.toLowerCase() === name.toLowerCase())?.value

      // Extract email addresses from headers
      const parseEmailList = (headerValue: string | undefined) => {
        if (!headerValue) return []
        return headerValue.split(',').map(email => email.trim()).filter(email => email.length > 0)
      }

      // Get email body
      let bodyText = ''
      let bodyHtml = ''
      
      if (message.payload?.body?.data) {
        bodyText = atob(message.payload.body.data.replace(/-/g, '+').replace(/_/g, '/'))
      } else if (message.payload?.parts) {
        for (const part of message.payload.parts) {
          if (part.mimeType === 'text/plain' && part.body?.data) {
            bodyText = atob(part.body.data.replace(/-/g, '+').replace(/_/g, '/'))
          } else if (part.mimeType === 'text/html' && part.body?.data) {
            bodyHtml = atob(part.body.data.replace(/-/g, '+').replace(/_/g, '/'))
          }
        }
      }

      // Parse labels
      const labels = message.labelIds || []

      return {
        userId,
        messageId: message.id,
        threadId: message.threadId,
        historyId: message.historyId,
        subject: getHeader('Subject') || '',
        fromEmail: getHeader('From') || '',
        fromName: getHeader('From')?.split('<')[0]?.trim() || '',
        toEmails: parseEmailList(getHeader('To')),
        ccEmails: parseEmailList(getHeader('Cc')),
        bccEmails: parseEmailList(getHeader('Bcc')),
        bodyText: bodyText.length > 0 ? bodyText : null,
        bodyHtml: bodyHtml.length > 0 ? bodyHtml : null,
        snippet: message.snippet || '',
        isRead: !labels.includes('UNREAD'),
        isImportant: labels.includes('IMPORTANT'),
        isStarred: labels.includes('STARRED'),
        labels,
        attachments: [], // TODO: Process attachments if needed
        receivedAt: new Date(parseInt(message.internalDate)).toISOString(),
        sentAt: new Date(parseInt(message.internalDate)).toISOString(),
        syncedAt: new Date().toISOString(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }
    })

    // Batch insert emails into Supabase
    if (emailsToInsert.length > 0) {
      // Insert in batches of 100 to avoid API limits
      const batchSize = 100
      let insertedCount = 0

      for (let i = 0; i < emailsToInsert.length; i += batchSize) {
        const batch = emailsToInsert.slice(i, i + batchSize)
        
        const { error: insertError } = await supabase
          .from('gmail_emails')
          .upsert(batch, { onConflict: 'userId,messageId' })

        if (insertError) {
          console.error(`❌ [GMAIL SYNC] Error inserting batch ${i / batchSize + 1}:`, insertError)
          throw new Error(`Failed to store emails: ${insertError.message}`)
        }

        insertedCount += batch.length
        console.log(`🔄 [GMAIL SYNC] Inserted batch ${i / batchSize + 1}: ${batch.length} emails`)
      }

      console.log(`✅ [GMAIL SYNC] Successfully stored ${insertedCount} emails`)
    }

    // Update Google Meet account with sync metadata
    const updateData = {
      last_synced_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    const { error: updateError } = await supabase
      .from('google_meet_accounts')
      .update(updateData)
      .eq('user_id', userId)

    if (updateError) {
      console.error('❌ [GMAIL SYNC] Error updating Google Meet account:', updateError)
      // Don't throw here as the sync was successful
    }

    console.log(`✅ [GMAIL SYNC] Date range sync completed for user: ${userId}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        messagesCount: newMessages.length,
        duplicatesSkipped: existingMessageIds.size,
        totalFound: allMessages.length,
        message: 'Gmail sync completed successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ [GMAIL SYNC] Error:', error)
    
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
