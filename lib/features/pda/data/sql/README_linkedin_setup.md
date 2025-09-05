# LinkedIn Database Setup

## 🚀 Quick Setup Instructions

### Step 1: Run the Enhanced LinkedIn Tables Script

1. Go to your **Supabase Dashboard**
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `create_enhanced_linkedin_tables.sql`
4. Click **Run** to execute the script

### Step 2: Verify Tables Created

After running the script, you should see these tables in your **Table Editor**:

- ✅ `linkedin_accounts` - Enhanced profile data
- ✅ `linkedin_posts` - Comprehensive posts data  
- ✅ `linkedin_connections` - Connections data (for future use)

### Step 3: Test the Enhanced Integration

Your LinkedIn integration is now ready to collect:

#### 📊 **Profile Data:**
- Basic info (name, email, profile picture)
- Professional info (headline, industry, summary)
- Location data
- Custom LinkedIn URL (vanity name)
- OAuth scopes tracking

#### 📝 **Posts Data:**
- Text posts and articles
- Images, videos, and documents
- Engagement metrics (likes, comments, shares, views)
- Post metadata and language detection
- Sponsored post detection

#### 🔗 **Connections Data:**
- Connection profiles and companies
- Mutual connections count
- Professional relationships

## 🎯 What's Different from Before

### ✅ **Enhanced Features:**
- **Comprehensive data collection** from all LinkedIn APIs
- **Media support** for images, videos, documents
- **Engagement tracking** with real-time metrics
- **Author information** for posts
- **Language detection** for content
- **Sponsored post detection**
- **OAuth scopes tracking**

### ✅ **Database Optimizations:**
- **Performance indexes** for fast queries
- **JSONB fields** for flexible metadata storage
- **Proper foreign keys** and constraints
- **Automatic timestamps** with triggers

## 🔧 Troubleshooting

### If you get permission errors:
```sql
-- Grant permissions to your app user (replace 'your_app_user' with actual user)
GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_accounts TO your_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_posts TO your_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_connections TO your_app_user;
```

### If tables already exist:
The script automatically drops old tables, so you can run it safely.

## 🚀 Ready to Go!

Your LinkedIn integration is now **100% ready** for comprehensive data collection with the enhanced Supabase function!
