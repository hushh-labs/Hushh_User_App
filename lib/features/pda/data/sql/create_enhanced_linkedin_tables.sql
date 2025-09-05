-- Enhanced LinkedIn tables for comprehensive data collection
-- This replaces the old LinkedIn tables with a complete schema ready for all LinkedIn API data
-- 
-- IMPORTANT: This will DROP existing LinkedIn tables and recreate them
-- Make sure to backup any important data before running this script

-- Drop existing LinkedIn tables if they exist
DROP TABLE IF EXISTS linkedin_posts CASCADE;
DROP TABLE IF EXISTS linkedin_accounts CASCADE;
DROP TABLE IF EXISTS linkedin_connections CASCADE;

-- Create enhanced LinkedIn accounts table
CREATE TABLE linkedin_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL REFERENCES hush_users("userId") ON DELETE CASCADE,
  
  -- Basic profile data (from OpenID Connect + enhanced API)
  linkedin_id VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255),
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  headline VARCHAR(500),
  profile_picture_url TEXT,
  vanity_name VARCHAR(255), -- LinkedIn public profile URL slug
  
  -- Enhanced profile data (from LinkedIn v2 API)
  industry VARCHAR(255),
  summary TEXT, -- Profile summary/about section
  public_profile_url TEXT, -- Full LinkedIn profile URL
  
  -- Location data
  location_name VARCHAR(255),
  location_country VARCHAR(255),
  
  -- OAuth tokens and scopes
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMP WITH TIME ZONE,
  oauth_scopes TEXT[] DEFAULT '{}', -- Array of granted OAuth scopes
  
  -- Metadata
  connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_synced_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_linkedin_account_per_user UNIQUE (user_id, linkedin_id)
);

-- Create enhanced LinkedIn posts table
CREATE TABLE linkedin_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL REFERENCES hush_users("userId") ON DELETE CASCADE,
  linkedin_account_id UUID NOT NULL REFERENCES linkedin_accounts(id) ON DELETE CASCADE,
  
  -- Post identifiers
  post_id VARCHAR(255) NOT NULL,
  
  -- Post content
  content TEXT,
  post_type VARCHAR(50), -- text, article, image, video, document, etc.
  visibility VARCHAR(50), -- PUBLIC, CONNECTIONS, etc.
  
  -- Author information
  author_name VARCHAR(255),
  author_headline VARCHAR(500),
  author_profile_picture_url TEXT,
  
  -- Media content
  media_urls TEXT[], -- Array of media URLs (images, videos, documents)
  article_url TEXT, -- If it's an article share
  article_title VARCHAR(500),
  article_description TEXT,
  
  -- Engagement metrics
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  
  -- Post metadata
  post_metadata JSONB DEFAULT '{}', -- Additional post data (reactions, media details, etc.)
  language VARCHAR(10), -- Post language code
  is_sponsored BOOLEAN DEFAULT false, -- Whether post is sponsored/advertisement
  
  -- Timestamps
  posted_at TIMESTAMP WITH TIME ZONE,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_linkedin_post_per_user UNIQUE (user_id, post_id)
);

-- Create LinkedIn connections table (for future use)
CREATE TABLE linkedin_connections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL REFERENCES hush_users("userId") ON DELETE CASCADE,
  linkedin_account_id UUID NOT NULL REFERENCES linkedin_accounts(id) ON DELETE CASCADE,
  
  -- Connection identifiers
  connection_id VARCHAR(255) NOT NULL, -- LinkedIn connection URN
  
  -- Connection profile data
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  email VARCHAR(255),
  profile_url VARCHAR(500),
  profile_picture_url VARCHAR(500),
  headline VARCHAR(500),
  industry VARCHAR(255),
  location VARCHAR(255),
  company_name VARCHAR(255),
  position VARCHAR(255),
  
  -- Connection metadata
  connected_at TIMESTAMP WITH TIME ZONE,
  mutual_connections_count INTEGER DEFAULT 0,
  
  -- Sync metadata
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_linkedin_connection_per_user UNIQUE (user_id, connection_id)
);

-- Create comprehensive indexes for performance
-- LinkedIn accounts indexes
CREATE INDEX idx_linkedin_accounts_user_id ON linkedin_accounts(user_id);
CREATE INDEX idx_linkedin_accounts_linkedin_id ON linkedin_accounts(linkedin_id);
CREATE INDEX idx_linkedin_accounts_active ON linkedin_accounts(user_id, is_active);
CREATE INDEX idx_linkedin_accounts_email ON linkedin_accounts(email);
CREATE INDEX idx_linkedin_accounts_industry ON linkedin_accounts(industry);
CREATE INDEX idx_linkedin_accounts_last_sync ON linkedin_accounts(last_synced_at);
CREATE INDEX idx_linkedin_accounts_oauth_scopes ON linkedin_accounts USING GIN(oauth_scopes);

-- LinkedIn posts indexes
CREATE INDEX idx_linkedin_posts_user_id ON linkedin_posts(user_id);
CREATE INDEX idx_linkedin_posts_account_id ON linkedin_posts(linkedin_account_id);
CREATE INDEX idx_linkedin_posts_posted_at ON linkedin_posts(posted_at DESC);
CREATE INDEX idx_linkedin_posts_type ON linkedin_posts(post_type);
CREATE INDEX idx_linkedin_posts_visibility ON linkedin_posts(visibility);
CREATE INDEX idx_linkedin_posts_author_name ON linkedin_posts(author_name);
CREATE INDEX idx_linkedin_posts_language ON linkedin_posts(language);
CREATE INDEX idx_linkedin_posts_sponsored ON linkedin_posts(is_sponsored);
CREATE INDEX idx_linkedin_posts_views ON linkedin_posts(views_count DESC);
CREATE INDEX idx_linkedin_posts_likes ON linkedin_posts(like_count DESC);
CREATE INDEX idx_linkedin_posts_metadata ON linkedin_posts USING GIN(post_metadata);

-- LinkedIn connections indexes
CREATE INDEX idx_linkedin_connections_user_id ON linkedin_connections(user_id);
CREATE INDEX idx_linkedin_connections_account_id ON linkedin_connections(linkedin_account_id);
CREATE INDEX idx_linkedin_connections_connection_id ON linkedin_connections(connection_id);
CREATE INDEX idx_linkedin_connections_company ON linkedin_connections(company_name);
CREATE INDEX idx_linkedin_connections_industry ON linkedin_connections(industry);

-- Create or replace the updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_linkedin_accounts_updated_at
    BEFORE UPDATE ON linkedin_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_linkedin_posts_updated_at
    BEFORE UPDATE ON linkedin_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_linkedin_connections_updated_at
    BEFORE UPDATE ON linkedin_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comprehensive comments for documentation
COMMENT ON TABLE linkedin_accounts IS 'Enhanced LinkedIn user accounts with comprehensive profile data from all available LinkedIn APIs';
COMMENT ON TABLE linkedin_posts IS 'Enhanced LinkedIn posts with full content, media, and engagement data from Share on LinkedIn API';
COMMENT ON TABLE linkedin_connections IS 'LinkedIn connections data (for future implementation)';

-- Column comments for linkedin_accounts
COMMENT ON COLUMN linkedin_accounts.linkedin_id IS 'LinkedIn user ID from API';
COMMENT ON COLUMN linkedin_accounts.vanity_name IS 'Custom LinkedIn URL slug (e.g., linkedin.com/in/vanity_name)';
COMMENT ON COLUMN linkedin_accounts.industry IS 'User industry from LinkedIn profile';
COMMENT ON COLUMN linkedin_accounts.summary IS 'User profile summary/about section';
COMMENT ON COLUMN linkedin_accounts.public_profile_url IS 'Full LinkedIn public profile URL';
COMMENT ON COLUMN linkedin_accounts.oauth_scopes IS 'Array of OAuth scopes granted to the app';

-- Column comments for linkedin_posts
COMMENT ON COLUMN linkedin_posts.post_id IS 'LinkedIn post URN or ID';
COMMENT ON COLUMN linkedin_posts.content IS 'Post text content';
COMMENT ON COLUMN linkedin_posts.post_type IS 'Type of post: text, article, image, video, document';
COMMENT ON COLUMN linkedin_posts.visibility IS 'Post visibility: PUBLIC, CONNECTIONS, etc.';
COMMENT ON COLUMN linkedin_posts.media_urls IS 'Array of media URLs (images, videos, documents)';
COMMENT ON COLUMN linkedin_posts.article_url IS 'URL of shared article';
COMMENT ON COLUMN linkedin_posts.post_metadata IS 'Additional post metadata (JSON) - reactions, media details, etc.';
COMMENT ON COLUMN linkedin_posts.language IS 'Language code of the post content';
COMMENT ON COLUMN linkedin_posts.is_sponsored IS 'Whether this is a sponsored/advertisement post';
COMMENT ON COLUMN linkedin_posts.views_count IS 'Number of views this post has received';

-- Column comments for linkedin_connections
COMMENT ON COLUMN linkedin_connections.connection_id IS 'LinkedIn connection URN';
COMMENT ON COLUMN linkedin_connections.company_name IS 'Connection current company';
COMMENT ON COLUMN linkedin_connections.position IS 'Connection current position';
COMMENT ON COLUMN linkedin_connections.mutual_connections_count IS 'Number of mutual connections';

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_accounts TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_posts TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON linkedin_connections TO your_app_user;
