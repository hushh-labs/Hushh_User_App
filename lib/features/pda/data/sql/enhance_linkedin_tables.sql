-- Enhancement script for LinkedIn tables to support comprehensive data collection
-- Run this AFTER the basic tables are created

-- Add additional fields to linkedin_posts table for enhanced data collection
ALTER TABLE linkedin_posts 
ADD COLUMN IF NOT EXISTS post_metadata JSONB DEFAULT '{}', -- Store additional post metadata
ADD COLUMN IF NOT EXISTS author_name VARCHAR(255), -- Post author name
ADD COLUMN IF NOT EXISTS author_headline VARCHAR(500), -- Post author headline
ADD COLUMN IF NOT EXISTS author_profile_picture_url TEXT, -- Post author profile picture
ADD COLUMN IF NOT EXISTS language VARCHAR(10), -- Post language
ADD COLUMN IF NOT EXISTS is_sponsored BOOLEAN DEFAULT false, -- Whether post is sponsored
ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0; -- Post view count

-- Add additional fields to linkedin_accounts table for enhanced profile data
ALTER TABLE linkedin_accounts 
ADD COLUMN IF NOT EXISTS industry VARCHAR(255), -- User's industry
ADD COLUMN IF NOT EXISTS summary TEXT, -- User's profile summary
ADD COLUMN IF NOT EXISTS public_profile_url TEXT, -- Full LinkedIn profile URL
ADD COLUMN IF NOT EXISTS oauth_scopes TEXT[] DEFAULT '{}'; -- Store granted OAuth scopes

-- Create additional indexes for better performance
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_author_name ON linkedin_posts(author_name);
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_language ON linkedin_posts(language);
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_sponsored ON linkedin_posts(is_sponsored);
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_views ON linkedin_posts(views_count DESC);

CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_industry ON linkedin_accounts(industry);
CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_oauth_scopes ON linkedin_accounts USING GIN(oauth_scopes);

-- Add comments for documentation
COMMENT ON COLUMN linkedin_posts.post_metadata IS 'Additional post metadata (JSON) - reactions, media details, etc.';
COMMENT ON COLUMN linkedin_posts.author_name IS 'Name of the post author';
COMMENT ON COLUMN linkedin_posts.author_headline IS 'Professional headline of the post author';
COMMENT ON COLUMN linkedin_posts.language IS 'Language code of the post content';
COMMENT ON COLUMN linkedin_posts.is_sponsored IS 'Whether this is a sponsored/advertisement post';
COMMENT ON COLUMN linkedin_posts.views_count IS 'Number of views this post has received';

COMMENT ON COLUMN linkedin_accounts.industry IS 'User industry from LinkedIn profile';
COMMENT ON COLUMN linkedin_accounts.summary IS 'User profile summary/about section';
COMMENT ON COLUMN linkedin_accounts.public_profile_url IS 'Full LinkedIn public profile URL';
COMMENT ON COLUMN linkedin_accounts.oauth_scopes IS 'Array of OAuth scopes granted to the app';
