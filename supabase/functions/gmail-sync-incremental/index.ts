import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  userId: string
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
    const { userId }: RequestBody = await req.json()

    console.log(`🔄 [GMAIL INCREMENTAL] Starting incremental sync for user: ${userId}`)

    // Get Gmail account from Supabase
    const { data: gmailAccount, error: accountError } = await supabase
      .from('gmail_accounts')
      .select('*')
      .eq('userId', userId)
      .single()

    if (accountError || !gmailAccount) {
      throw new Error('Gmail account not found or not connected')
    }

    if (!gmailAccount.isConnected) {
      throw new Error('Gmail account is not connected')
    }

    // Setup Gmail API client
    let accessToken = gmailAccount.accessToken
    const refreshToken = gmailAccount.refreshToken

    if (!accessToken && !refreshToken) {
      throw new Error('No valid tokens found for Gmail API access')
    }

    // Helper to refresh access token using refresh_token
    async function refreshAccessToken(): Promise<string | null> {
      try {
        if (!refreshToken) return null;

        // Prefer Gmail creds; fall back to Google Meet creds if Gmail not set
        const clientId =
          Deno.env.get('GMAIL_CLIENT_ID') || Deno.env.get('GOOGLE_MEET_CLIENT_ID')
        const clientSecret =
          Deno.env.get('GMAIL_CLIENT_SECRET') || Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')
        if (!clientId || !clientSecret) {
          console.error('❌ [GMAIL INCREMENTAL] Missing OAuth CLIENT_ID/SECRET (looked for GMAIL_* then GOOGLE_MEET_*)')
          return null
        }

        if (Deno.env.get('GMAIL_CLIENT_ID')) {
          console.log('🔐 [GMAIL INCREMENTAL] Using GMAIL_CLIENT_ID/SECRET for refresh')
        } else {
          console.log('🔐 [GMAIL INCREMENTAL] Using GOOGLE_MEET_CLIENT_ID/SECRET for refresh (fallback)')
        }

        const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            client_id: clientId,
            client_secret: clientSecret,
            refresh_token: refreshToken,
            grant_type: 'refresh_token',
          }),
        })

        if (!tokenResp.ok) {
          const t = await tokenResp.text()
          console.error(`❌ [GMAIL INCREMENTAL] Token refresh failed: ${t}`)
          return null
        }

        const tokenJson = await tokenResp.json()
        const newAccessToken = tokenJson.access_token as string | undefined
        const expiresIn = tokenJson.expires_in as number | undefined
        if (!newAccessToken) {
          console.error('❌ [GMAIL INCREMENTAL] Token refresh response missing access_token')
          return null
        }

        // Persist new access token
        const { error: tokenUpdateError } = await supabase
          .from('gmail_accounts')
          .update({
            accessToken: newAccessToken,
            accessTokenExpiresAt: expiresIn ? new Date(Date.now() + expiresIn * 1000).toISOString() : null,
            updated_at: new Date().toISOString(),
          })
          .eq('userId', userId)

        if (tokenUpdateError) {
          console.error('❌ [GMAIL INCREMENTAL] Failed to persist refreshed token:', tokenUpdateError)
        } else {
          console.log('🔐 [GMAIL INCREMENTAL] Access token refreshed and stored')
        }

        return newAccessToken
      } catch (e) {
        console.error('❌ [GMAIL INCREMENTAL] Error refreshing token:', e)
        return null
      }
    }

    // Helper function to make Gmail API requests with rate limiting and 401 refresh
    async function makeGmailRequest(url: string, token: string, retryCount = 0, refreshed = false) {
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        const errorText = await response.text()

        // On unauthorized, attempt single refresh and retry once
        if (response.status === 401 && !refreshed) {
          console.log('🔐 [GMAIL INCREMENTAL] Access token expired, attempting refresh...')
          const newToken = await refreshAccessToken()
          if (newToken) {
            accessToken = newToken
            return makeGmailRequest(url, accessToken, retryCount, true)
          }
        }

        // Handle rate limiting with exponential backoff
        if (response.status === 429 && retryCount < 3) {
          const delay = Math.pow(2, retryCount) * 1000 // 1s, 2s, 4s
          console.log(`⚠️ [GMAIL INCREMENTAL] Rate limited, retrying in ${delay}ms (attempt ${retryCount + 1})`)
          await new Promise(resolve => setTimeout(resolve, delay))
          return makeGmailRequest(url, token, retryCount + 1, refreshed)
        }

        throw new Error(`Gmail API error: ${response.status} - ${errorText}`)
      }

      return response.json()
    }

    // If there is a refresh token and the access token is missing, refresh first
    if (!accessToken && refreshToken) {
      const newToken = await refreshAccessToken()
      if (!newToken) throw new Error('Failed to refresh access token')
      accessToken = newToken
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
            console.error(`❌ [GMAIL INCREMENTAL] Error processing item:`, error)
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

    // Get the last history ID for incremental sync
    const lastHistoryId = gmailAccount.historyId

    let newMessages = []
    let newHistoryId = lastHistoryId

    if (lastHistoryId) {
      console.log(`🔄 [GMAIL INCREMENTAL] Using history ID: ${lastHistoryId}`)

      // Use Gmail History API for incremental sync
      try {
        const historyUrl = `https://gmail.googleapis.com/gmail/v1/users/me/history?startHistoryId=${lastHistoryId}&historyTypes=messageAdded`
        const historyResult = await makeGmailRequest(historyUrl, accessToken)

        if (historyResult.history) {
          console.log(`🔄 [GMAIL INCREMENTAL] Found ${historyResult.history.length} history records`)

          // Extract new message IDs from history
          const messageIds = new Set()
          for (const historyRecord of historyResult.history) {
            if (historyRecord.messagesAdded) {
              for (const messageAdded of historyRecord.messagesAdded) {
                messageIds.add(messageAdded.message.id)
              }
            }
          }

          // Get full message details for new messages
          if (messageIds.size > 0) {
            console.log(`🔄 [GMAIL INCREMENTAL] Fetching ${messageIds.size} new messages`)

            // Get full message details using batch processing
            newMessages = await processBatch(
              Array.from(messageIds),
              3, // Process 3 messages at a time for incremental sync
              async (messageId: any) => {
                const messageUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}`
                return makeGmailRequest(messageUrl, accessToken)
              }
            )
          }

          newHistoryId = historyResult.historyId || lastHistoryId
        } else {
          console.log('🔄 [GMAIL INCREMENTAL] No new history found')
        }
      } catch (error) {
        console.log(`⚠️ [GMAIL INCREMENTAL] History API failed, falling back to recent messages: ${error.message}`)
        
        // Fallback: Get recent messages (last 24 hours)
        const yesterday = new Date()
        yesterday.setDate(yesterday.getDate() - 1)
        const searchQuery = `after:${Math.floor(yesterday.getTime() / 1000)}`
        
        const searchUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${encodeURIComponent(searchQuery)}&maxResults=50`
        const searchResult = await makeGmailRequest(searchUrl, accessToken)
        
        if (searchResult.messages) {
          // Get full message details using batch processing
          newMessages = await processBatch(
            searchResult.messages,
            3, // Process 3 messages at a time for fallback
            async (msg: any) => {
              const messageUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}`
              return makeGmailRequest(messageUrl, accessToken)
            }
          )
        }
      }
    } else {
      console.log('🔄 [GMAIL INCREMENTAL] No history ID found, fetching recent messages')
      
      // First sync: Get recent messages (last 7 days)
      const weekAgo = new Date()
      weekAgo.setDate(weekAgo.getDate() - 7)
      const searchQuery = `after:${Math.floor(weekAgo.getTime() / 1000)}`
      
      const searchUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${encodeURIComponent(searchQuery)}&maxResults=100`
      const searchResult = await makeGmailRequest(searchUrl, accessToken)
      
      if (searchResult.messages) {
        // Get full message details using batch processing
        newMessages = await processBatch(
          searchResult.messages,
          3, // Process 3 messages at a time for first sync
          async (msg: any) => {
            const messageUrl = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}`
            return makeGmailRequest(messageUrl, accessToken)
          }
        )
        newHistoryId = newMessages.length > 0 ? newMessages[0].historyId : null
      }
    }

    console.log(`🔄 [GMAIL INCREMENTAL] Found ${newMessages.length} new messages`)

    // Check for existing emails to avoid duplicates
    if (newMessages.length > 0) {
      const messageIds = newMessages.map(msg => msg.id)
      const { data: existingEmails } = await supabase
        .from('gmail_emails')
        .select('messageId')
        .eq('userId', userId)
        .in('messageId', messageIds)

      const existingMessageIds = new Set(existingEmails?.map(email => email.messageId) || [])
      const uniqueNewMessages = newMessages.filter(msg => !existingMessageIds.has(msg.id))
      
      console.log(`🔄 [GMAIL INCREMENTAL] ${existingMessageIds.size} emails already exist, syncing ${uniqueNewMessages.length} new emails`)

      // Process and store new messages in Supabase
      if (uniqueNewMessages.length > 0) {
        const emailsToInsert = uniqueNewMessages.map(message => {
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

      // Insert emails into Supabase
      const { error: insertError } = await supabase
        .from('gmail_emails')
        .upsert(emailsToInsert, { onConflict: 'userId,messageId' })

      if (insertError) {
        console.error('❌ [GMAIL INCREMENTAL] Error inserting emails:', insertError)
        throw new Error(`Failed to store emails: ${insertError.message}`)
      }

        console.log(`✅ [GMAIL INCREMENTAL] Successfully stored ${uniqueNewMessages.length} emails`)
      } else {
        console.log(`🔄 [GMAIL INCREMENTAL] No new emails to store (all were duplicates)`)
      }
    }

    // Update Gmail account with new sync metadata
    const updateData = {
      lastSyncAt: new Date().toISOString(),
      historyId: newHistoryId,
      updated_at: new Date().toISOString(),
    }

    const { error: updateError } = await supabase
      .from('gmail_accounts')
      .update(updateData)
      .eq('userId', userId)

    if (updateError) {
      console.error('❌ [GMAIL INCREMENTAL] Error updating account:', updateError)
      // Don't throw here as the sync was successful
    }

    // Get total email count for response
    const { count } = await supabase
      .from('gmail_emails')
      .select('id', { count: 'exact' })
      .eq('userId', userId)

    console.log(`✅ [GMAIL INCREMENTAL] Incremental sync completed for user: ${userId}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        newMessagesCount: newMessages.length,
        totalMessagesCount: count || 0,
        message: 'Incremental Gmail sync completed successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ [GMAIL INCREMENTAL] Error:', error)
    
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
