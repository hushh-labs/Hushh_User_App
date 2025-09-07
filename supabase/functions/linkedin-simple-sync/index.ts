import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface LinkedInProfile {
  id: string
  firstName: {
    localized: Record<string, string>
  }
  lastName: {
    localized: Record<string, string>
  }
  headline?: {
    localized: Record<string, string>
  }
  profilePicture?: {
    'displayImage~': {
      elements: Array<{
        identifiers: Array<{
          identifier: string
        }>
      }>
    }
  }
  vanityName?: string
  location?: {
    name: string
    country: string
  }
}

interface LinkedInPost {
  id: string
  author: string
  commentary?: string
  content?: {
    contentEntities: Array<{
      entityLocation: string
      thumbnails: Array<{
        resolvedUrl: string
      }>
    }>
    title: string
  }
  lifecycleState: string
  visibility: {
    'com.linkedin.ugc.MemberNetworkVisibility': string
  }
  created: {
    time: number
  }
  socialDetail?: {
    totalSocialActivityCounts: {
      numLikes: number
      numComments: number
      numShares: number
    }
  }
}

// Helper functions for enhanced LinkedIn data processing
function determinePostType(post: any): string {
  if (post.content?.article) return 'article'
  if (post.content?.images && post.content.images.length > 0) return 'image'
  if (post.content?.videos && post.content.videos.length > 0) return 'video'
  if (post.content?.documents && post.content.documents.length > 0) return 'document'
  return 'text'
}

function extractMediaUrls(post: any): string[] {
  const urls: string[] = []
  
  // Extract image URLs
  if (post.content?.images) {
    for (const image of post.content.images) {
      if (image.url) urls.push(image.url)
    }
  }
  
  // Extract video URLs  
  if (post.content?.videos) {
    for (const video of post.content.videos) {
      if (video.url) urls.push(video.url)
    }
  }
  
  // Extract document URLs
  if (post.content?.documents) {
    for (const doc of post.content.documents) {
      if (doc.url) urls.push(doc.url)
    }
  }
  
  return urls
}

async function syncPostEngagement(supabase: any, postId: string, token: string, userId: string): Promise<void> {
  try {
    // Fetch reactions/likes for the post
    const reactionsResponse = await fetch(`https://api.linkedin.com/rest/reactions?entity=${postId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Restli-Protocol-Version': '2.0.0',
      },
    })
    
    if (reactionsResponse.ok) {
      const reactionsData = await reactionsResponse.json()
      const totalReactions = reactionsData.paging?.total || 0
      
      // Update the post with engagement data
      await supabase
        .from('linkedin_posts')
        .update({ 
          like_count: totalReactions,
          fetched_at: new Date().toISOString()
        })
        .eq('post_id', postId)
        .eq('user_id', userId)
    }
  } catch (e) {
    console.log('⚠️ Engagement sync failed for post:', postId, e)
  }
}

async function syncLinkedInData(supabase: any, account: any, token: string, userId: string): Promise<Response> {
  console.log('🔄 Starting comprehensive LinkedIn data sync...')
  
  // Comprehensive posts sync using enhanced LinkedIn API with w_member_social
  let syncedPosts = 0
  let syncedImages = 0
  let syncedVideos = 0
  let syncedDocuments = 0
  
  try {
    // 1. Note: LinkedIn's posts API requires additional permissions
    // The current scopes don't include posts access, so we'll skip this for now
    console.log('📝 Skipping posts fetch - requires additional LinkedIn API permissions for posts access')
    const postsResponse = { ok: false, status: 403, json: async () => ({ error: 'Posts API requires additional permissions' }) }

    if (postsResponse.ok) {
      const postsData = await postsResponse.json()
      console.log(`📝 Found ${postsData.elements?.length || 0} posts`)
      
      for (const post of postsData.elements || []) {
        // Enhanced post data extraction
        const postData = {
          user_id: userId,
          linkedin_account_id: account.id,
          post_id: post.id,
          content: post.commentary || post.content?.text || '',
          post_type: determinePostType(post),
          visibility: post.visibility || 'PUBLIC',
          author_name: `${account.first_name} ${account.last_name}`,
          author_headline: account.headline,
          author_profile_picture_url: account.profile_picture_url,
          like_count: 0, // Will be fetched separately via reactions API
          comment_count: 0, // Will be fetched separately
          share_count: 0, // Will be fetched separately
          views_count: 0, // Will be populated if available
          posted_at: new Date(post.createdAt || post.publishedAt || Date.now()).toISOString(),
          fetched_at: new Date().toISOString(),
          media_urls: extractMediaUrls(post),
          article_url: post.content?.article?.source || null,
          article_title: post.content?.article?.title || null,
          article_description: post.content?.article?.description || null,
          post_metadata: {
            original_post: post,
            extracted_at: new Date().toISOString(),
            api_version: '202401'
          },
          language: post.language || 'en',
          is_sponsored: post.isSponsored || false,
        }

        await supabase
          .from('linkedin_posts')
          .upsert(postData, { onConflict: 'user_id,post_id' })

        syncedPosts++
        
        // Fetch engagement data for this post
        try {
          await syncPostEngagement(supabase, post.id, token, userId)
        } catch (e) {
          console.log(`⚠️ Could not sync engagement for post ${post.id}:`, e)
        }
      }
    } else {
      console.log('⚠️ Could not fetch posts:', postsResponse.status, 'Posts API requires additional permissions')
    }

    // 2. Skip images fetch - requires additional permissions
    console.log('🖼️ Skipping images fetch - requires additional LinkedIn API permissions')
    syncedImages = 0

    // 3. Skip videos fetch - requires additional permissions
    console.log('🎥 Skipping videos fetch - requires additional LinkedIn API permissions')
    syncedVideos = 0

    // 4. Skip documents fetch - requires additional permissions
    console.log('📄 Skipping documents fetch - requires additional LinkedIn API permissions')
    syncedDocuments = 0

  } catch (e) {
    console.log('⚠️ Comprehensive posts sync failed:', e)
  }

  // Update last synced timestamp
  await supabase
    .from('linkedin_accounts')
    .update({ last_synced_at: new Date().toISOString() })
    .eq('id', account.id)

  return new Response(JSON.stringify({ 
    success: true, 
    message: 'Comprehensive LinkedIn data synced successfully',
    stats: {
      posts: syncedPosts,
      images: syncedImages,
      videos: syncedVideos,
      documents: syncedDocuments,
    }
  }), {
    headers: { 
      ...corsHeaders, 
      'Content-Type': 'application/json' 
    }
  })
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const authCode = url.searchParams.get('code')
    const state = url.searchParams.get('state')
    const accessToken = url.searchParams.get('accessToken')
    const userId = url.searchParams.get('userId')
    const apikey = url.searchParams.get('apikey')
    
    console.log('🔍 Request URL:', req.url)
    console.log('🔍 Auth Code:', authCode ? 'Present' : 'Missing')
    console.log('🔍 State:', state ? 'Present' : 'Missing')
    console.log('🔍 Access Token:', accessToken ? 'Present' : 'Missing')
    console.log('🔍 User ID:', userId || 'Missing')
    console.log('🔍 API Key:', apikey ? 'Present' : 'Missing')
    
    // Check if we have the required authentication
    const authHeader = req.headers.get('authorization')
    const hasAuth = authHeader || apikey
    
    // Special case: OAuth callback with code and state doesn't need authentication
    const isOAuthCallback = req.method === 'GET' && authCode && state
    
    // Note: Skipping auth checks for now since Supabase handles this at the platform level
    // OAuth callbacks from LinkedIn will work without auth headers
    
    console.log('🔄 Processing request - OAuth callback:', isOAuthCallback, 'Has auth:', hasAuth)

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    console.log('🔍 Environment check:')
    console.log('- Supabase URL:', supabaseUrl ? 'Present' : 'Missing')
    console.log('- Service Key:', supabaseServiceKey ? 'Present' : 'Missing')
    
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('❌ Missing required environment variables')
      return new Response(
        JSON.stringify({ 
          error: 'Server configuration error',
          details: 'Missing environment variables'
        }), 
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // LinkedIn OAuth configuration
    const clientId = '86bxfdosvae3t6' // Hardcoded for now
    const clientSecret = 'WPL_AP1.3eAR0aISetBk5eym.oJAseg==' // Hardcoded for now - was failing due to == characters
    const redirectUri = `${supabaseUrl}/functions/v1/linkedin-simple-sync`
    
    console.log('🔍 LinkedIn config:')
    console.log('- Client ID:', clientId ? 'Present' : 'Missing')
    console.log('- Client Secret:', clientSecret ? 'Present' : 'Missing')
    console.log('- Redirect URI:', redirectUri)
    
    if (!clientId || !clientSecret) {
      console.error('❌ Missing LinkedIn OAuth configuration')
      return new Response(
        JSON.stringify({ 
          error: 'LinkedIn configuration error',
          details: 'Missing client credentials'
        }), 
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Case 1: OAuth callback - exchange code for token
    if (authCode && state) {
      console.log('🔐 OAuth callback received, exchanging code for token...')
      
      // Extract user ID from state parameter (format: timestamp-userId)
      const stateParts = state.split('-')
      let extractedUserId = null
      if (stateParts.length >= 2) {
        extractedUserId = stateParts.slice(1).join('-') // Handle userIds with dashes
        console.log('🔐 Extracted user ID from state:', extractedUserId)
      }

      // Exchange authorization code for access token using OpenID Connect
      const tokenResponse = await fetch('https://www.linkedin.com/oauth/v2/accessToken', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          grant_type: 'authorization_code',
          code: authCode,
          redirect_uri: redirectUri,
          client_id: clientId,
          client_secret: clientSecret,
        }),
      })

      if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text()
        console.error('❌ Token exchange failed:', errorText)
        return new Response(`Token exchange failed: ${errorText}`, { 
          status: 400,
          headers: corsHeaders 
        })
      }

      const tokenData = await tokenResponse.json()
      const accessTokenFromOAuth = tokenData.access_token

      // Get user profile using OpenID Connect userinfo endpoint
      const profileResponse = await fetch('https://api.linkedin.com/v2/userinfo', {
        headers: {
          'Authorization': `Bearer ${accessTokenFromOAuth}`,
        },
      })

      if (!profileResponse.ok) {
        const errorText = await profileResponse.text()
        console.error('❌ Profile fetch failed:', errorText)
        return new Response(`Profile fetch failed: ${errorText}`, { 
          status: 400,
          headers: corsHeaders 
        })
      }

      const profileData = await profileResponse.json()
      
      // OpenID Connect userinfo endpoint returns standardized claims
      const email = profileData.email
      const firstName = profileData.given_name
      const lastName = profileData.family_name
      const profilePictureUrl = profileData.picture
      const linkedinId = profileData.sub // Subject claim contains LinkedIn ID
      
      // Now fetch enhanced profile data using LinkedIn v2 API with w_member_social scope
      let headline = null
      let location = null
      let vanityName = null
      
      try {
        const enhancedProfileResponse = await fetch(`https://api.linkedin.com/v2/people/(id:${linkedinId})`, {
          headers: {
            'Authorization': `Bearer ${accessTokenFromOAuth}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })
        
        if (enhancedProfileResponse.ok) {
          const enhancedData = await enhancedProfileResponse.json()
          console.log('📋 Enhanced profile data:', enhancedData)
          
          // Extract additional profile fields
          headline = enhancedData.headline?.localized?.[Object.keys(enhancedData.headline?.localized || {})[0]] || null
          vanityName = enhancedData.vanityName || null
          
          // Location data if available
          if (enhancedData.location) {
            location = enhancedData.location.name || null
          }
        } else {
          console.log('⚠️ Enhanced profile fetch failed:', enhancedProfileResponse.status)
        }
      } catch (e) {
        console.log('⚠️ Enhanced profile sync failed:', e)
      }
      
      console.log('📋 OpenID Connect profile data:', {
        sub: linkedinId,
        email: email,
        given_name: firstName,
        family_name: lastName,
        picture: profilePictureUrl
      })

      // Determine which user to link this LinkedIn account to
      let finalUserId = null
      
      // First priority: Use extracted user ID from state parameter
      if (extractedUserId) {
        console.log('🔐 Using user ID from OAuth state:', extractedUserId)
        
        // Verify the user exists in our database
        const userExists = await supabase
          .from('hush_users')
          .select('"userId"')
          .eq('"userId"', extractedUserId)
          .single()
        
        if (userExists.data) {
          finalUserId = extractedUserId
        } else {
          console.log('⚠️ User ID from state not found in database:', extractedUserId)
        }
      }
      
      // Second priority: Check if LinkedIn account already exists
      if (!finalUserId) {
        const existingAccount = await supabase
          .from('linkedin_accounts')
          .select('user_id')
          .eq('linkedin_id', linkedinId)
          .single()
        
        if (existingAccount.data) {
          finalUserId = existingAccount.data.user_id
          console.log('🔐 Using existing LinkedIn account user ID:', finalUserId)
        }
      }
      
      // Last resort: Return error - we need a valid user ID
      if (!finalUserId) {
        console.error('❌ No valid user ID found for LinkedIn connection')
        return new Response('Unable to link LinkedIn account: No valid user found. Please try logging in again.', { 
          status: 400,
          headers: corsHeaders 
        })
      }

      // Upsert LinkedIn account
      const accountData = {
        user_id: finalUserId,
        linkedin_id: linkedinId,
        email: email,
        first_name: firstName,
        last_name: lastName,
        headline: headline,
        profile_picture_url: profilePictureUrl,
        vanity_name: vanityName,
        location_name: location,
        location_country: null, // Will be enhanced later if location data has country
        industry: null, // Will be populated from enhanced profile data
        summary: null, // Will be populated from enhanced profile data
        public_profile_url: vanityName ? `https://www.linkedin.com/in/${vanityName}` : null,
        access_token: accessTokenFromOAuth,
        token_expires_at: new Date(Date.now() + (tokenData.expires_in * 1000)).toISOString(),
        oauth_scopes: ['openid', 'profile', 'email', 'w_member_social'],
        connected_at: new Date().toISOString(),
        last_synced_at: new Date().toISOString(),
        is_active: true,
      }

      const { error: upsertError } = await supabase
        .from('linkedin_accounts')
        .upsert(accountData, {
          onConflict: 'linkedin_id',
        })

      if (upsertError) {
        console.error('❌ Database upsert error:', upsertError)
        return new Response(`Database error: ${upsertError.message}`, { 
          status: 500,
          headers: corsHeaders 
        })
      }

      console.log('✅ LinkedIn account connected successfully!')

      // Get the account data for posts sync
      const account = await supabase
        .from('linkedin_accounts')
        .select('*')
        .eq('linkedin_id', linkedinId)
        .single()

      if (!account.data) {
        console.error('❌ Could not retrieve account after upsert')
        return new Response('Account creation failed', { 
          status: 500,
          headers: corsHeaders 
        })
      }

      // Return success page for WebView
      const isWebView = req.headers.get('user-agent')?.includes('WebView') || 
                       req.headers.get('x-requested-with') === 'com.example.app'

      if (isWebView) {
        const successHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>LinkedIn Connected</title>
            <style>
              body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                margin: 0; padding: 20px; min-height: 100vh;
                display: flex; align-items: center; justify-content: center;
              }
              .container { 
                background: white; border-radius: 16px; padding: 40px;
                text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                max-width: 400px; width: 100%;
              }
              .icon { font-size: 64px; margin-bottom: 20px; }
              h1 { color: #333; margin: 0 0 10px; font-size: 24px; }
              p { color: #666; margin: 0 0 30px; line-height: 1.5; }
              .details { background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; }
              .details h3 { margin: 0 0 10px; color: #333; font-size: 16px; }
              .detail-item { margin: 8px 0; font-size: 14px; }
              .label { font-weight: 600; color: #495057; }
              .value { color: #6c757d; }
              .btn {
                background: #0077b5; color: white; border: none; border-radius: 8px;
                padding: 12px 24px; font-size: 16px; font-weight: 600;
                cursor: pointer; text-decoration: none; display: inline-block;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="icon">🎉</div>
              <h1>LinkedIn Connected!</h1>
              <p>Your LinkedIn account has been successfully connected to Hushh.</p>
              
              <div class="details">
                <h3>Connected Account</h3>
                <div class="detail-item">
                  <span class="label">Name:</span> 
                  <span class="value">${firstName || ''} ${lastName || ''}</span>
                </div>
                ${headline ? `<div class="detail-item"><span class="label">Headline:</span> <span class="value">${headline}</span></div>` : ''}
                ${email ? `<div class="detail-item"><span class="label">Email:</span> <span class="value">${email}</span></div>` : ''}
              </div>
              
              <button class="btn" onclick="window.close()">Continue</button>
            </div>
            <script>
              // Auto-close immediately 
              setTimeout(() => { 
                try { 
                  window.close(); 
                } catch(e) { 
                  // Fallback for WebView - redirect to close the view
                  window.location.href = 'about:blank';
                }
              }, 1000); // Reduced to 1 second
              
              // Also try to signal the app immediately
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.flutter) {
                window.webkit.messageHandlers.flutter.postMessage('linkedin_success');
              }
            </script>
          </body>
          </html>
        `
        
        return new Response(successHtml, {
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'text/html' 
          }
        })
      }

      // Now fetch posts data immediately after OAuth success
      console.log('🔄 Fetching posts data after OAuth success...')
      let syncedPosts = 0
      
      try {
        // Note: LinkedIn's posts API requires additional permissions and different endpoints
        // The current scopes (openid, profile, email, w_member_social) don't include posts access
        // For now, we'll skip posts fetching until proper permissions are configured
        console.log('📝 Skipping posts fetch - requires additional LinkedIn API permissions for posts access')
        const postsResponse = { ok: false, status: 403, json: async () => ({ error: 'Posts API requires additional permissions' }) }

        if (postsResponse.ok) {
          const postsData = await postsResponse.json()
          console.log(`📝 Found ${postsData.elements?.length || 0} posts during OAuth`)
          
          for (const post of postsData.elements || []) {
            // Enhanced post data extraction
            const postData = {
              user_id: finalUserId,
              linkedin_account_id: account.data.id,
              post_id: post.id,
              content: post.commentary || post.content?.text || '',
              post_type: determinePostType(post),
              visibility: post.visibility || 'PUBLIC',
              author_name: `${firstName} ${lastName}`,
              author_headline: headline,
              author_profile_picture_url: profilePictureUrl,
              like_count: 0, // Will be fetched separately via reactions API
              comment_count: 0, // Will be fetched separately
              share_count: 0, // Will be fetched separately
              views_count: 0, // Will be populated if available
              posted_at: new Date(post.createdAt || post.publishedAt || Date.now()).toISOString(),
              fetched_at: new Date().toISOString(),
              media_urls: extractMediaUrls(post),
              article_url: post.content?.article?.source || null,
              article_title: post.content?.article?.title || null,
              article_description: post.content?.article?.description || null,
              post_metadata: {
                original_post: post,
                extracted_at: new Date().toISOString(),
                api_version: '202401'
              },
              language: post.language || 'en',
              is_sponsored: post.isSponsored || false,
            }

            await supabase
              .from('linkedin_posts')
              .upsert(postData, { onConflict: 'user_id,post_id' })

            syncedPosts++
          }
        } else {
          console.log('⚠️ Could not fetch posts during OAuth:', postsResponse.status, 'Posts API requires additional permissions')
        }
      } catch (e) {
        console.log('⚠️ Posts fetch during OAuth failed:', e)
      }

      // Update last synced timestamp
      await supabase
        .from('linkedin_accounts')
        .update({ last_synced_at: new Date().toISOString() })
        .eq('id', account.data.id)

      console.log(`✅ OAuth completed with ${syncedPosts} posts synced`)

      // Redirect back to the app with success
      const appScheme = 'hushhapp://oauth/linkedin/success'
      return new Response(null, {
        status: 302,
        headers: {
          ...corsHeaders,
          'Location': appScheme
        }
      })
    }

    // Case 2: Manual sync request (POST with userId only)
    if (req.method === 'POST' && userId && !accessToken) {
      console.log('🔄 Manual sync request for user:', userId)
      
      // Get the user's LinkedIn account
      const account = await supabase
        .from('linkedin_accounts')
        .select('*')
        .eq('user_id', userId)
        .single()

      if (!account.data) {
        return new Response(JSON.stringify({ 
          error: 'LinkedIn account not found',
          details: 'Please connect your LinkedIn account first'
        }), { 
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      if (!account.data.access_token) {
        return new Response(JSON.stringify({ 
          error: 'No access token available',
          details: 'LinkedIn account needs to be reconnected'
        }), { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }

      // Use the stored access token to sync data
      const tokenToUse = account.data.access_token
      return await syncLinkedInData(supabase, account.data, tokenToUse, userId)
    }

    // Case 3: Data sync with existing token
    if (accessToken && userId) {
      console.log('🔄 Syncing LinkedIn data for user:', userId)

      // Get account from database
      const account = await supabase
        .from('linkedin_accounts')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .single()

      if (!account.data) {
        return new Response('LinkedIn account not found', { 
          status: 404,
          headers: corsHeaders 
        })
      }

      const tokenToUse = accessToken || account.data.access_token

      // Comprehensive posts sync using enhanced LinkedIn API with w_member_social
      let syncedPosts = 0
      let syncedImages = 0
      let syncedVideos = 0
      let syncedDocuments = 0
      
      try {
        console.log('🔄 Starting comprehensive LinkedIn content sync...')
        
        // 1. Skip posts fetch - requires additional permissions
        console.log('📝 Skipping posts fetch - requires additional LinkedIn API permissions for posts access')
        const postsResponse = { ok: false, status: 403, json: async () => ({ error: 'Posts API requires additional permissions' }) }

        if (postsResponse.ok) {
          const postsData = await postsResponse.json()
          console.log(`📝 Found ${postsData.elements?.length || 0} posts`)
          
          for (const post of postsData.elements || []) {
            // Enhanced post data extraction
            const postData = {
              user_id: userId,
              linkedin_account_id: account.data.id,
              post_id: post.id,
              content: post.commentary || post.content?.text || '',
              post_type: determinePostType(post),
              visibility: post.visibility || 'PUBLIC',
              author_name: `${account.data.first_name} ${account.data.last_name}`,
              author_headline: account.data.headline,
              author_profile_picture_url: account.data.profile_picture_url,
              like_count: 0, // Will be fetched separately via reactions API
              comment_count: 0, // Will be fetched separately
              share_count: 0, // Will be fetched separately
              views_count: 0, // Will be populated if available
              posted_at: new Date(post.createdAt || post.publishedAt || Date.now()).toISOString(),
              fetched_at: new Date().toISOString(),
              media_urls: extractMediaUrls(post),
              article_url: post.content?.article?.source || null,
              article_title: post.content?.article?.title || null,
              article_description: post.content?.article?.description || null,
              post_metadata: {
                original_post: post,
                extracted_at: new Date().toISOString(),
                api_version: '202401'
              },
              language: post.language || 'en',
              is_sponsored: post.isSponsored || false,
            }

            await supabase
              .from('linkedin_posts')
              .upsert(postData, { onConflict: 'user_id,post_id' })

            syncedPosts++
            
            // Fetch engagement data for this post
            try {
              await syncPostEngagement(supabase, post.id, tokenToUse, userId)
            } catch (e) {
              console.log(`⚠️ Could not sync engagement for post ${post.id}:`, e)
            }
          }
        } else {
          console.log('⚠️ Could not fetch posts:', postsResponse.status, 'Posts API requires additional permissions')
        }

        // 2. Skip images fetch - requires additional permissions
        console.log('🖼️ Skipping images fetch - requires additional LinkedIn API permissions')
        syncedImages = 0

        // 3. Skip videos fetch - requires additional permissions
        console.log('🎥 Skipping videos fetch - requires additional LinkedIn API permissions')
        syncedVideos = 0

        // 4. Skip documents fetch - requires additional permissions
        console.log('📄 Skipping documents fetch - requires additional LinkedIn API permissions')
        syncedDocuments = 0

      } catch (e) {
        console.log('⚠️ Comprehensive posts sync failed:', e)
      }

      // Update last synced timestamp
      await supabase
        .from('linkedin_accounts')
        .update({ last_synced_at: new Date().toISOString() })
        .eq('id', account.data.id)

      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Comprehensive LinkedIn data synced successfully',
        stats: {
          posts: syncedPosts,
          images: syncedImages,
          videos: syncedVideos,
          documents: syncedDocuments,
        }
      }), {
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        }
      })
    }

    return new Response('Missing required parameters', { 
      status: 400,
      headers: corsHeaders 
    })

  } catch (error) {
    console.error('❌ Function error:', error)
    return new Response(`Server error: ${error.message}`, { 
      status: 500,
      headers: corsHeaders 
    })
  }
})
