import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  authCode?: string
  accessToken?: string
  email: string
  userId: string
  profileId?: string
  syncOptions?: {
    includePosts: boolean
    includeConnections: boolean
    includeProfile: boolean
    includePositions: boolean
    includeEducation: boolean
    includeSkills: boolean
    includeCertifications: boolean
    includeMessages: boolean
    durationDays: number
  }
}

interface LinkedInProfile {
  id: string
  localizedFirstName?: string
  localizedLastName?: string
  profilePicture?: any
  headline?: string
  vanityName?: string
}

interface LinkedInEmailResponse {
  elements: Array<{
    'handle~': {
      emailAddress: string
    }
  }>
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
    const { 
      authCode, 
      accessToken, 
      email, 
      userId, 
      profileId,
      syncOptions = {
        includePosts: true,
        includeConnections: true,
        includeProfile: true,
        includePositions: true,
        includeEducation: true,
        includeSkills: true,
        includeCertifications: true,
        includeMessages: false,
        durationDays: 30
      }
    }: RequestBody = await req.json()

    console.log(`🔗 [LINKEDIN SYNC] Processing comprehensive sync for user: ${userId}`)

    // Validate required parameters
    if (!email || !userId) {
      throw new Error('Missing required parameters: email and userId')
    }

    if (!authCode && !accessToken) {
      throw new Error('Either authCode or accessToken is required')
    }

    // LinkedIn OAuth configuration
    const LINKEDIN_CLIENT_ID = '86bxfdosvae3t6' // Hardcoded for now
    const LINKEDIN_CLIENT_SECRET = 'WPL_AP1.3eAR0aISetBk5eym.oJAseg==' // Hardcoded for now - was failing due to == characters
    const LINKEDIN_REDIRECT_URI = 'https://biiqwforuvzgubrrkfgq.supabase.co/functions/v1/linkedin-simple-sync'
    
    console.log(`🔗 [LINKEDIN SYNC] Using Client ID: ${LINKEDIN_CLIENT_ID?.substring(0, 20)}...`)
    console.log(`🔗 [LINKEDIN SYNC] Redirect URI: ${LINKEDIN_REDIRECT_URI}`)

    let linkedinAccessToken = accessToken
    let refreshToken: string | undefined
    let expiresAt: Date | undefined

    // If we have an auth code, exchange it for access token
    if (authCode && !accessToken) {
      console.log(`🔗 [LINKEDIN SYNC] Exchanging auth code for access token...`)
      
      const tokenResponse = await fetch('https://www.linkedin.com/oauth/v2/accessToken', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          grant_type: 'authorization_code',
          code: authCode,
          client_id: LINKEDIN_CLIENT_ID,
          client_secret: LINKEDIN_CLIENT_SECRET,
          redirect_uri: LINKEDIN_REDIRECT_URI,
        }),
      })

      if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text()
        console.error(`❌ [LINKEDIN SYNC] Token exchange failed: ${errorText}`)
        throw new Error(`LinkedIn token exchange failed: ${errorText}`)
      }

      const tokenData = await tokenResponse.json()
      linkedinAccessToken = tokenData.access_token
      refreshToken = tokenData.refresh_token
      
      if (tokenData.expires_in) {
        expiresAt = new Date(Date.now() + tokenData.expires_in * 1000)
      }

      console.log(`✅ [LINKEDIN SYNC] Successfully exchanged auth code for access token`)
    }

    if (!linkedinAccessToken) {
      throw new Error('No access token available')
    }

    // Comprehensive data collection
    const collectedData: any = {}

    // 1. Fetch basic profile information
    if (syncOptions.includeProfile) {
      console.log(`👤 [LINKEDIN SYNC] Fetching profile information...`)
      
      try {
        const profileResponse = await fetch('https://api.linkedin.com/v2/people/~', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (profileResponse.ok) {
          const profile: LinkedInProfile = await profileResponse.json()
          collectedData.profile = profile
          console.log(`✅ [LINKEDIN SYNC] Profile data collected`)
        }

        // Get email address
        const emailResponse = await fetch('https://api.linkedin.com/v2/emailAddress?q=members&projection=(elements*(handle~))', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (emailResponse.ok) {
          const emailData: LinkedInEmailResponse = await emailResponse.json()
          if (emailData.elements && emailData.elements.length > 0) {
            collectedData.email = emailData.elements[0]['handle~'].emailAddress
          }
        }

      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching profile: ${error}`)
      }
    }

    // 2. Fetch positions/work experience
    if (syncOptions.includePositions) {
      console.log(`💼 [LINKEDIN SYNC] Fetching positions...`)
      
      try {
        const positionsResponse = await fetch('https://api.linkedin.com/v2/people/~/positions', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (positionsResponse.ok) {
          const positionsData = await positionsResponse.json()
          collectedData.positions = positionsData.elements || []
          console.log(`✅ [LINKEDIN SYNC] ${collectedData.positions.length} positions collected`)
        }
      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching positions: ${error}`)
      }
    }

    // 3. Fetch education
    if (syncOptions.includeEducation) {
      console.log(`🎓 [LINKEDIN SYNC] Fetching education...`)
      
      try {
        const educationResponse = await fetch('https://api.linkedin.com/v2/people/~/educations', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (educationResponse.ok) {
          const educationData = await educationResponse.json()
          collectedData.education = educationData.elements || []
          console.log(`✅ [LINKEDIN SYNC] ${collectedData.education.length} education records collected`)
        }
      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching education: ${error}`)
      }
    }

    // 4. Fetch skills
    if (syncOptions.includeSkills) {
      console.log(`🛠️ [LINKEDIN SYNC] Fetching skills...`)
      
      try {
        const skillsResponse = await fetch('https://api.linkedin.com/v2/people/~/skills', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (skillsResponse.ok) {
          const skillsData = await skillsResponse.json()
          collectedData.skills = skillsData.elements || []
          console.log(`✅ [LINKEDIN SYNC] ${collectedData.skills.length} skills collected`)
        }
      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching skills: ${error}`)
      }
    }

    // 5. Fetch posts/shares
    if (syncOptions.includePosts) {
      console.log(`📝 [LINKEDIN SYNC] Fetching posts...`)
      
      try {
        const postsResponse = await fetch('https://api.linkedin.com/v2/shares?q=owners&owners=urn:li:person:' + (collectedData.profile?.id || profileId), {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (postsResponse.ok) {
          const postsData = await postsResponse.json()
          collectedData.posts = postsData.elements || []
          console.log(`✅ [LINKEDIN SYNC] ${collectedData.posts.length} posts collected`)
        }
      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching posts: ${error}`)
      }
    }

    // 6. Fetch connections (limited by LinkedIn API)
    if (syncOptions.includeConnections) {
      console.log(`🤝 [LINKEDIN SYNC] Fetching connections...`)
      
      try {
        const connectionsResponse = await fetch('https://api.linkedin.com/v2/people/~/connections', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (connectionsResponse.ok) {
          const connectionsData = await connectionsResponse.json()
          collectedData.connections = connectionsData.elements || []
          console.log(`✅ [LINKEDIN SYNC] ${collectedData.connections.length} connections collected`)
        }
      } catch (error) {
        console.warn(`⚠️ [LINKEDIN SYNC] Error fetching connections: ${error}`)
      }
    }

    // Store comprehensive account information
    console.log(`💾 [LINKEDIN SYNC] Storing comprehensive account data...`)
    
    const accountData = {
      userId: userId,
      isConnected: true,
      provider: 'linkedin',
      email: collectedData.email || email,
      profileId: collectedData.profile?.id || profileId,
      vanityName: collectedData.profile?.vanityName,
      accessToken: linkedinAccessToken,
      refreshToken: refreshToken,
      scopes: ['r_liteprofile', 'r_emailaddress', 'w_member_social', 'r_fullprofile'],
      tokenExpiresAt: expiresAt?.toISOString(),
      firstName: collectedData.profile?.localizedFirstName,
      lastName: collectedData.profile?.localizedLastName,
      headline: collectedData.profile?.headline,
      profilePictureUrl: collectedData.profile?.profilePicture?.displayImage,
      connectedAt: new Date().toISOString(),
      lastSyncAt: new Date().toISOString(),
      syncSettings: syncOptions,
      updated_at: new Date().toISOString(),
    }

    const { error: upsertError } = await supabase
      .from('linkedin_accounts')
      .upsert(accountData, { onConflict: 'userId' })

    if (upsertError) {
      console.error(`❌ [LINKEDIN SYNC] Account upsert error:`, upsertError)
      throw new Error(`Failed to store LinkedIn account: ${upsertError.message}`)
    }

    // Store collected data in respective tables
    let totalRecords = 0

    // Store positions
    if (collectedData.positions && collectedData.positions.length > 0) {
      const positionsToInsert = collectedData.positions.map((position: any, index: number) => ({
        userId: userId,
        positionId: position.id || `pos_${Date.now()}_${index}`,
        title: position.title,
        companyName: position.companyName,
        description: position.description,
        isCurrent: position.isCurrent || false,
        startDate: position.startDate ? new Date(position.startDate.year, position.startDate.month - 1).toISOString() : null,
        endDate: position.endDate ? new Date(position.endDate.year, position.endDate.month - 1).toISOString() : null,
        syncedAt: new Date().toISOString(),
      }))

      const { error: positionsError } = await supabase
        .from('linkedin_positions')
        .upsert(positionsToInsert, { onConflict: 'userId,positionId' })

      if (!positionsError) {
        totalRecords += positionsToInsert.length
        console.log(`✅ [LINKEDIN SYNC] Stored ${positionsToInsert.length} positions`)
      }
    }

    // Store education
    if (collectedData.education && collectedData.education.length > 0) {
      const educationToInsert = collectedData.education.map((edu: any, index: number) => ({
        userId: userId,
        educationId: edu.id || `edu_${Date.now()}_${index}`,
        schoolName: edu.schoolName,
        fieldOfStudy: edu.fieldOfStudy,
        degree: edu.degreeName,
        startDate: edu.startDate ? new Date(edu.startDate.year, edu.startDate.month - 1).toISOString() : null,
        endDate: edu.endDate ? new Date(edu.endDate.year, edu.endDate.month - 1).toISOString() : null,
        syncedAt: new Date().toISOString(),
      }))

      const { error: educationError } = await supabase
        .from('linkedin_education')
        .upsert(educationToInsert, { onConflict: 'userId,educationId' })

      if (!educationError) {
        totalRecords += educationToInsert.length
        console.log(`✅ [LINKEDIN SYNC] Stored ${educationToInsert.length} education records`)
      }
    }

    // Store skills
    if (collectedData.skills && collectedData.skills.length > 0) {
      const skillsToInsert = collectedData.skills.map((skill: any, index: number) => ({
        userId: userId,
        skillId: skill.id || `skill_${Date.now()}_${index}`,
        skillName: skill.name,
        numEndorsements: skill.numEndorsements || 0,
        syncedAt: new Date().toISOString(),
      }))

      const { error: skillsError } = await supabase
        .from('linkedin_skills')
        .upsert(skillsToInsert, { onConflict: 'userId,skillId' })

      if (!skillsError) {
        totalRecords += skillsToInsert.length
        console.log(`✅ [LINKEDIN SYNC] Stored ${skillsToInsert.length} skills`)
      }
    }

    // Store posts
    if (collectedData.posts && collectedData.posts.length > 0) {
      const postsToInsert = collectedData.posts.map((post: any) => ({
        userId: userId,
        postId: post.id,
        authorId: post.author,
        text: post.text?.text || '',
        publishedAt: post.publishedAt ? new Date(post.publishedAt).toISOString() : new Date().toISOString(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        syncedAt: new Date().toISOString(),
      }))

      const { error: postsError } = await supabase
        .from('linkedin_posts')
        .upsert(postsToInsert, { onConflict: 'userId,postId' })

      if (!postsError) {
        totalRecords += postsToInsert.length
        console.log(`✅ [LINKEDIN SYNC] Stored ${postsToInsert.length} posts`)
      }
    }

    console.log(`✅ [LINKEDIN SYNC] Comprehensive sync completed for user ${userId}`)
    console.log(`📊 [LINKEDIN SYNC] Total records stored: ${totalRecords}`)

    // For in-app WebView, return HTML success page instead of JSON
    const isInAppRequest = req.headers.get('user-agent')?.includes('Mobile') || 
                          req.headers.get('accept')?.includes('text/html')

    if (isInAppRequest || authCode) {
      // Return HTML success page for in-app WebView
      const successHtml = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>LinkedIn Connected</title>
          <style>
            body { 
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              text-align: center; 
              padding: 50px 20px; 
              background: linear-gradient(135deg, #0077B5 0%, #005885 100%);
              color: white;
              margin: 0;
            }
            .container {
              max-width: 400px;
              margin: 0 auto;
              background: rgba(255,255,255,0.1);
              padding: 40px 30px;
              border-radius: 16px;
              backdrop-filter: blur(10px);
            }
            .icon { font-size: 64px; margin-bottom: 20px; }
            h1 { margin: 20px 0; font-size: 24px; }
            .stats { 
              margin: 30px 0; 
              padding: 20px; 
              background: rgba(255,255,255,0.1); 
              border-radius: 12px; 
            }
            .stat { margin: 8px 0; font-size: 14px; opacity: 0.9; }
            .close-btn {
              background: white;
              color: #0077B5;
              border: none;
              padding: 12px 24px;
              border-radius: 8px;
              font-weight: bold;
              cursor: pointer;
              margin-top: 20px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="icon">✅</div>
            <h1>LinkedIn Connected Successfully!</h1>
            <p>Your comprehensive LinkedIn data has been synced.</p>
            
            <div class="stats">
              <div class="stat">📊 Profile: ${collectedData.profile ? 1 : 0} record</div>
              <div class="stat">💼 Positions: ${collectedData.positions?.length || 0} records</div>
              <div class="stat">🎓 Education: ${collectedData.education?.length || 0} records</div>
              <div class="stat">🛠️ Skills: ${collectedData.skills?.length || 0} records</div>
              <div class="stat">📝 Posts: ${collectedData.posts?.length || 0} records</div>
              <div class="stat">🤝 Connections: ${collectedData.connections?.length || 0} records</div>
              <div class="stat"><strong>Total: ${totalRecords} records synced</strong></div>
            </div>
            
            <p style="font-size: 14px; opacity: 0.8;">You can now close this window and return to the app.</p>
            <button class="close-btn" onclick="window.close()">Close</button>
          </div>
          
          <script>
            // Auto-close after 5 seconds if possible
            setTimeout(() => {
              try {
                window.close();
              } catch (e) {
                console.log('Cannot auto-close window');
              }
            }, 5000);
          </script>
        </body>
        </html>
      `
      
      return new Response(successHtml, {
        headers: { ...corsHeaders, 'Content-Type': 'text/html' },
        status: 200,
      })
    }

    // Return JSON response for API calls
    return new Response(
      JSON.stringify({
        success: true,
        message: 'LinkedIn comprehensive sync completed successfully',
        data: {
          userId: userId,
          email: collectedData.email || email,
          profileId: collectedData.profile?.id || profileId,
          isConnected: true,
          connectedAt: new Date().toISOString(),
          summary: {
            profile: collectedData.profile ? 1 : 0,
            positions: collectedData.positions?.length || 0,
            education: collectedData.education?.length || 0,
            skills: collectedData.skills?.length || 0,
            posts: collectedData.posts?.length || 0,
            connections: collectedData.connections?.length || 0,
            totalRecords: totalRecords
          },
          syncOptions: syncOptions
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error(`❌ [LINKEDIN SYNC] Error:`, error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'LinkedIn comprehensive sync failed',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
