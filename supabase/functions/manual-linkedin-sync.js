// Manual LinkedIn Sync Script
// Use this to sync posts for existing LinkedIn users

const SUPABASE_URL = 'https://biiqwforuvzgubrrkfgq.supabase.co'
const FUNCTION_URL = `${SUPABASE_URL}/functions/v1/linkedin-simple-sync`

// Replace with your actual user ID
const USER_ID = 'your-user-id-here'

async function manualLinkedInSync() {
  try {
    console.log('🔄 Starting manual LinkedIn sync for user:', USER_ID)
    
    const response = await fetch(FUNCTION_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, // You'll need to add your anon key
      },
      body: JSON.stringify({
        userId: USER_ID
      })
    })
    
    const result = await response.json()
    
    if (response.ok) {
      console.log('✅ Sync successful!')
      console.log('📊 Stats:', result.stats)
    } else {
      console.error('❌ Sync failed:', result)
    }
    
  } catch (error) {
    console.error('❌ Error:', error)
  }
}

// Run the sync
manualLinkedInSync()
