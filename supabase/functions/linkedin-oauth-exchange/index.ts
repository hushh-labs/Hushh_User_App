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
  firstName?: string
  lastName?: string
  profileUrl?: string
  profilePictureUrl?: string
  headline?: string
  industry?: string
  location?: string
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
      firstName,
      lastName,
      profileUrl,
      profilePictureUrl,
      headline,
      industry,
      location
    }: RequestBody = await req.json()

    console.log(`🔗 [LINKEDIN OAUTH] Processing OAuth exchange for user: ${userId}`)

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
    
    console.log(`🔗 [LINKEDIN OAUTH] Using Client ID: ${LINKEDIN_CLIENT_ID?.substring(0, 20)}...`)
    console.log(`🔗 [LINKEDIN OAUTH] Client Secret present: ${LINKEDIN_CLIENT_SECRET ? 'Yes' : 'No'}`)
    console.log(`🔗 [LINKEDIN OAUTH] Redirect URI: ${LINKEDIN_REDIRECT_URI}`)

    let linkedinAccessToken = accessToken
    let refreshToken: string | undefined
    let expiresAt: Date | undefined

    // If we have an auth code, exchange it for access token
    if (authCode && !accessToken) {
      console.log(`🔗 [LINKEDIN OAUTH] Exchanging auth code for access token...`)
      
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
        console.error(`❌ [LINKEDIN OAUTH] Token exchange failed: ${errorText}`)
        throw new Error(`LinkedIn token exchange failed: ${errorText}`)
      }

      const tokenData = await tokenResponse.json()
      linkedinAccessToken = tokenData.access_token
      refreshToken = tokenData.refresh_token
      
      if (tokenData.expires_in) {
        expiresAt = new Date(Date.now() + tokenData.expires_in * 1000)
      }

      console.log(`✅ [LINKEDIN OAUTH] Successfully exchanged auth code for access token`)
    }

    if (!linkedinAccessToken) {
      throw new Error('No access token available')
    }

    // Fetch user profile from LinkedIn API if not provided
    let profileData = {
      profileId,
      firstName,
      lastName,
      profileUrl,
      profilePictureUrl,
      headline,
      industry,
      location,
    }

    if (!profileId) {
      console.log(`👤 [LINKEDIN OAUTH] Fetching user profile from LinkedIn API...`)
      
      try {
        // Get basic profile information
        const profileResponse = await fetch('https://api.linkedin.com/v2/people/~', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (profileResponse.ok) {
          const profile = await profileResponse.json()
          profileData.profileId = profile.id
          profileData.firstName = profile.localizedFirstName
          profileData.lastName = profile.localizedLastName
          profileData.headline = profile.localizedHeadline
          
          // Construct profile URL
          if (profile.vanityName) {
            profileData.profileUrl = `https://www.linkedin.com/in/${profile.vanityName}`
          }
          
          console.log(`✅ [LINKEDIN OAUTH] Profile fetched successfully`)
        } else {
          console.warn(`⚠️ [LINKEDIN OAUTH] Failed to fetch profile: ${profileResponse.status}`)
        }

        // Get profile picture
        const pictureResponse = await fetch('https://api.linkedin.com/v2/people/~/profilePicture(displayImage~:playableStreams)', {
          headers: {
            'Authorization': `Bearer ${linkedinAccessToken}`,
            'X-Restli-Protocol-Version': '2.0.0',
          },
        })

        if (pictureResponse.ok) {
          const pictureData = await pictureResponse.json()
          const elements = pictureData?.displayImage?.elements
          if (elements && elements.length > 0) {
            // Get the largest image
            const largestImage = elements[elements.length - 1]
            profileData.profilePictureUrl = largestImage?.identifiers?.[0]?.identifier
          }
        }

      } catch (error) {
        console.warn(`⚠️ [LINKEDIN OAUTH] Error fetching profile: ${error}`)
        // Continue without profile data
      }
    }

    // Store/update LinkedIn account in database
    console.log(`💾 [LINKEDIN OAUTH] Storing LinkedIn account data...`)
    
    const { error: upsertError } = await supabase
      .from('linkedin_accounts')
      .upsert({
        userId: userId,
        isConnected: true,
        provider: 'linkedin',
        email: email,
        profileId: profileData.profileId,
        accessToken: linkedinAccessToken,
        refreshToken: refreshToken,
        scopes: ['r_liteprofile', 'r_emailaddress', 'w_member_social'],
        tokenExpiresAt: expiresAt?.toISOString(),
        firstName: profileData.firstName,
        lastName: profileData.lastName,
        profileUrl: profileData.profileUrl,
        profilePictureUrl: profileData.profilePictureUrl,
        headline: profileData.headline,
        industry: profileData.industry,
        location: profileData.location,
        connectedAt: new Date().toISOString(),
        lastSyncAt: null,
        syncSettings: {},
        updated_at: new Date().toISOString(),
      }, { 
        onConflict: 'userId' 
      })

    if (upsertError) {
      console.error(`❌ [LINKEDIN OAUTH] Database upsert error:`, upsertError)
      throw new Error(`Failed to store LinkedIn account: ${upsertError.message}`)
    }

    console.log(`✅ [LINKEDIN OAUTH] LinkedIn account stored successfully for user ${userId}`)

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: 'LinkedIn OAuth exchange completed successfully',
        data: {
          userId: userId,
          email: email,
          profileId: profileData.profileId,
          isConnected: true,
          connectedAt: new Date().toISOString(),
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error(`❌ [LINKEDIN OAUTH] Error:`, error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'LinkedIn OAuth exchange failed',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

