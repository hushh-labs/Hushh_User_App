import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.43.4'
import { corsHeaders } from '../_shared/cors.ts'

const GOOGLE_DRIVE_SCOPES = [
  'https://www.googleapis.com/auth/drive.metadata.readonly',
  'https://www.googleapis.com/auth/drive.readonly',
]

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // Support GET /callback just like Meet function
  const url = new URL(req.url)
  if (req.method === 'GET' && url.pathname.includes('/callback')) {
    const code = url.searchParams.get('code')
    const state = url.searchParams.get('state') // userId
    if (!code || !state) {
      return new Response(JSON.stringify({ success: false, message: 'Missing authorization code or state' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
    }

    // Optionally exchange tokens server-side and store account
    try {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      )

      const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          code,
          client_id: Deno.env.get('GOOGLE_MEET_CLIENT_ID')!,
          client_secret: Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')!,
          redirect_uri: Deno.env.get('GOOGLE_DRIVE_REDIRECT_URI')!,
          grant_type: 'authorization_code',
        }),
      })
      const tokenJson = await tokenRes.json()
      if (!tokenRes.ok) {
        return new Response(JSON.stringify({ success: false, message: tokenJson?.error_description || 'Token exchange failed' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      await supabase.from('google_drive_accounts').upsert({
        user_id: state,
        is_active: true,
        access_token: tokenJson.access_token,
        refresh_token: tokenJson.refresh_token,
        token_type: tokenJson.token_type,
        expires_in: tokenJson.expires_in,
        scope: tokenJson.scope,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id' })

      // Simple success page
      return new Response(
        `<!DOCTYPE html><html><head><title>Google Drive Connected</title><style>body{font-family:Arial,sans-serif;text-align:center;padding:50px}.success{color:#4CAF50}</style></head><body><h1 class="success">✅ Google Drive Connected</h1><p>You can close this window and return to the app.</p><script>setTimeout(()=>{window.close()},2000)</script></body></html>`,
        { headers: { 'Content-Type': 'text/html' }, status: 200 },
      )
    } catch (e) {
      return new Response(JSON.stringify({ success: false, message: String(e) }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 })
    }
  }

  try {
    const { action, userId, code } = await req.json()
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    if (!userId) {
      return new Response(JSON.stringify({ success: false, message: 'Missing userId' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
    }

    if (action === 'connect') {
      // Reuse Meet/Calendar OAuth client credentials
      const clientId = Deno.env.get('GOOGLE_MEET_CLIENT_ID')
      const redirectUri = Deno.env.get('GOOGLE_DRIVE_REDIRECT_URI')
      const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth')
      authUrl.searchParams.set('client_id', clientId!)
      authUrl.searchParams.set('redirect_uri', redirectUri!)
      authUrl.searchParams.set('response_type', 'code')
      authUrl.searchParams.set('access_type', 'offline')
      authUrl.searchParams.set('prompt', 'consent')
      authUrl.searchParams.set('scope', GOOGLE_DRIVE_SCOPES.join(' '))
      authUrl.searchParams.set('state', `drive:${userId}`)

      return new Response(JSON.stringify({ success: true, authUrl: authUrl.toString() }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (action === 'callback') {
      if (!code) {
        return new Response(JSON.stringify({ success: false, message: 'Missing code' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }
      // Exchange code for tokens via Google OAuth token endpoint (same client as Meet/Calendar)
      const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          code,
          client_id: Deno.env.get('GOOGLE_MEET_CLIENT_ID')!,
          client_secret: Deno.env.get('GOOGLE_MEET_CLIENT_SECRET')!,
          redirect_uri: Deno.env.get('GOOGLE_DRIVE_REDIRECT_URI')!,
          grant_type: 'authorization_code',
        }),
      })
      const tokenJson = await tokenRes.json()
      if (!tokenRes.ok) {
        return new Response(JSON.stringify({ success: false, message: tokenJson?.error_description || 'Token exchange failed' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      await supabase.from('google_drive_accounts').upsert({
        user_id: userId,
        is_active: true,
        access_token: tokenJson.access_token,
        refresh_token: tokenJson.refresh_token,
        token_type: tokenJson.token_type,
        expires_in: tokenJson.expires_in,
        scope: tokenJson.scope,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id' })

      // Trigger initial sync
      return new Response(JSON.stringify({ success: true, message: 'Drive connected', account: { user_id: userId } }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (action === 'sync') {
      // Fetch token
      const { data: acct, error: acctErr } = await supabase
        .from('google_drive_accounts')
        .select('*')
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle()
      if (acctErr || !acct) {
        return new Response(JSON.stringify({ success: false, message: 'Drive not connected' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
      }

      // List files with pagination
      let pageToken: string | undefined
      let upserted = 0
      do {
        const url = new URL('https://www.googleapis.com/drive/v3/files')
        url.searchParams.set('fields', 'nextPageToken, files(id, name, mimeType, size, createdTime, modifiedTime, shared, webViewLink, thumbnailLink, trashed)')
        url.searchParams.set('pageSize', '100')
        if (pageToken) url.searchParams.set('pageToken', pageToken)

        const res = await fetch(url.toString(), {
          headers: { Authorization: `Bearer ${acct.access_token}` },
        })
        const json = await res.json()
        if (!res.ok) {
          return new Response(JSON.stringify({ success: false, message: json?.error?.message || 'Drive API error' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
        }

        const files = json.files || []
        if (files.length) {
          const rows = files.map((f: any) => ({
            file_id: f.id,
            user_id: userId,
            name: f.name,
            mime_type: f.mimeType,
            size: f.size ? Number(f.size) : null,
            created_time: f.createdTime ? new Date(f.createdTime).toISOString() : null,
            modified_time: f.modifiedTime ? new Date(f.modifiedTime).toISOString() : null,
            shared: !!f.shared,
            web_view_link: f.webViewLink || null,
            thumbnail_link: f.thumbnailLink || null,
            trashed: !!f.trashed,
          }))
          const { error } = await supabase.from('DriveFile').upsert(rows, { onConflict: 'file_id' })
          if (error) {
            return new Response(JSON.stringify({ success: false, message: error.message }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
          }
          upserted += rows.length
        }
        pageToken = json.nextPageToken
      } while (pageToken)

      return new Response(JSON.stringify({ success: true, message: 'Drive synced', count: upserted }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ success: false, message: 'Unknown action' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 })
  } catch (e) {
    return new Response(JSON.stringify({ success: false, message: String(e) }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 })
  }
})
