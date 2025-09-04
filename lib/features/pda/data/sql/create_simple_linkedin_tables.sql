-- Simplified LinkedIn tables for data that's actually accessible via LinkedIn API (2024)
-- This focuses on: basic profile + posts + authentication

-- LinkedIn account table (basic profile data only)
CREATE TABLE linkedin_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL REFERENCES hush_users("userId") ON DELETE CASCADE,
  
  -- Basic profile data (available via OpenID Connect + r_liteprofile)
  linkedin_id VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255),
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  headline VARCHAR(500),
  profile_picture_url TEXT,
  vanity_name VARCHAR(255), -- LinkedIn public profile URL slug
  
  -- Location (if available)
  location_name VARCHAR(255),
  location_country VARCHAR(255),
  
  -- OAuth tokens
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_synced_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_linkedin_account_per_user UNIQUE (user_id, linkedin_id)
);

-- LinkedIn posts table (available with "Share on LinkedIn" product)
CREATE TABLE linkedin_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id VARCHAR(128) NOT NULL REFERENCES hush_users("userId") ON DELETE CASCADE,
  linkedin_account_id UUID NOT NULL REFERENCES linkedin_accounts(id) ON DELETE CASCADE,
  
  -- Post data
  post_id VARCHAR(255) NOT NULL,
  content TEXT,
  post_type VARCHAR(50), -- article, post, image, video, etc.
  visibility VARCHAR(50), -- public, connections, etc.
  
  -- Media
  media_urls TEXT[], -- Array of media URLs if any
  article_url TEXT, -- If it's an article
  
  -- Engagement metrics (if available)
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  
  -- Timestamps
  posted_at TIMESTAMP WITH TIME ZONE,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT unique_linkedin_post_per_user UNIQUE (user_id, post_id)
);

-- Indexes for performance
CREATE INDEX idx_linkedin_accounts_user_id ON linkedin_accounts(user_id);
CREATE INDEX idx_linkedin_accounts_linkedin_id ON linkedin_accounts(linkedin_id);
CREATE INDEX idx_linkedin_accounts_active ON linkedin_accounts(user_id, is_active);

CREATE INDEX idx_linkedin_posts_user_id ON linkedin_posts(user_id);
CREATE INDEX idx_linkedin_posts_account_id ON linkedin_posts(linkedin_account_id);
CREATE INDEX idx_linkedin_posts_posted_at ON linkedin_posts(posted_at DESC);
CREATE INDEX idx_linkedin_posts_type ON linkedin_posts(post_type);

-- Updated at trigger function (reuse existing one if available)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_linkedin_accounts_updated_at
    BEFORE UPDATE ON linkedin_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_linkedin_posts_updated_at
    BEFORE UPDATE ON linkedin_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE linkedin_accounts IS 'LinkedIn user accounts with basic profile data (limited by API restrictions)';
COMMENT ON TABLE linkedin_posts IS 'LinkedIn posts and articles (requires Share on LinkedIn product approval)';

COMMENT ON COLUMN linkedin_accounts.linkedin_id IS 'LinkedIn user ID from API';
COMMENT ON COLUMN linkedin_accounts.vanity_name IS 'Custom LinkedIn URL slug (e.g., linkedin.com/in/vanity_name)';
COMMENT ON COLUMN linkedin_posts.post_id IS 'LinkedIn post URN or ID';
COMMENT ON COLUMN linkedin_posts.content IS 'Post text content';
COMMENT ON COLUMN linkedin_posts.media_urls IS 'Array of image/video URLs attached to post';
