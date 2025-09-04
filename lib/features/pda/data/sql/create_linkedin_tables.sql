-- Create tables for storing LinkedIn data in Supabase
-- This follows the same pattern as Gmail integration
-- 
-- IMPORTANT: Run create_hush_users_table.sql FIRST before running this script
-- These tables reference the main hush_users table via foreign keys
-- 
-- Run this SQL in your Supabase dashboard to create the tables

-- Table for storing LinkedIn OAuth tokens and account information
CREATE TABLE IF NOT EXISTS linkedin_accounts (
    -- Primary key using userId from Firebase for consistency
    "userId" VARCHAR(128) PRIMARY KEY,
    
    -- Account connection status
    "isConnected" BOOLEAN DEFAULT false,
    "provider" VARCHAR(50) DEFAULT 'linkedin',
    "email" VARCHAR(255),
    "profileId" VARCHAR(255), -- LinkedIn member ID
    
    -- OAuth tokens (encrypted in production)
    "accessToken" TEXT,
    "refreshToken" TEXT,
    "scopes" TEXT[], -- Array of OAuth scopes
    "tokenExpiresAt" TIMESTAMP WITH TIME ZONE,
    
    -- LinkedIn profile data
    "firstName" VARCHAR(255),
    "lastName" VARCHAR(255),
    "profileUrl" VARCHAR(500),
    "profilePictureUrl" VARCHAR(500),
    "headline" VARCHAR(500),
    "industry" VARCHAR(255),
    "location" VARCHAR(255),
    
    -- Sync settings and metadata
    "lastSyncAt" TIMESTAMP WITH TIME ZONE,
    "syncSettings" JSONB DEFAULT '{}', -- Store sync preferences
    
    -- Timestamp fields
    "connectedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    "valid_email" CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_user_id CHECK (LENGTH("userId") > 0),
    CONSTRAINT valid_provider CHECK (provider = 'linkedin'),
    
    -- Foreign key to main users table
    CONSTRAINT fk_linkedin_accounts_user 
        FOREIGN KEY ("userId") REFERENCES hush_users("userId") 
        ON DELETE CASCADE
);

-- Table for storing LinkedIn posts and activity data
CREATE TABLE IF NOT EXISTS linkedin_posts (
    -- Primary key
    "id" BIGSERIAL PRIMARY KEY,
    
    -- Reference to user
    "userId" VARCHAR(128) NOT NULL,
    
    -- LinkedIn post identifiers
    "postId" VARCHAR(255) NOT NULL, -- LinkedIn post URN
    "authorId" VARCHAR(255) NOT NULL, -- LinkedIn author URN
    
    -- Post metadata
    "authorName" VARCHAR(255),
    "authorHeadline" VARCHAR(500),
    "authorProfilePictureUrl" VARCHAR(500),
    
    -- Post content
    "text" TEXT,
    "images" JSONB DEFAULT '[]', -- Array of image metadata
    "videos" JSONB DEFAULT '[]', -- Array of video metadata
    "documents" JSONB DEFAULT '[]', -- Array of document metadata
    "articleUrl" VARCHAR(500), -- If post shares an article
    "articleTitle" VARCHAR(500),
    "articleDescription" TEXT,
    
    -- Engagement data
    "likesCount" INTEGER DEFAULT 0,
    "commentsCount" INTEGER DEFAULT 0,
    "sharesCount" INTEGER DEFAULT 0,
    "viewsCount" INTEGER DEFAULT 0,
    
    -- Post properties
    "isSponsored" BOOLEAN DEFAULT false,
    "visibility" VARCHAR(50), -- PUBLIC, CONNECTIONS, etc.
    "language" VARCHAR(10),
    
    -- Date fields
    "publishedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "lastUpdatedAt" TIMESTAMP WITH TIME ZONE,
    
    -- Sync metadata
    "syncedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_user_id_posts CHECK (LENGTH("userId") > 0),
    CONSTRAINT valid_post_id CHECK (LENGTH("postId") > 0),
    CONSTRAINT valid_author_id CHECK (LENGTH("authorId") > 0),
    CONSTRAINT valid_published_at CHECK ("publishedAt" IS NOT NULL),
    
    -- Foreign key to main users table
    CONSTRAINT fk_linkedin_posts_user 
        FOREIGN KEY ("userId") REFERENCES hush_users("userId") 
        ON DELETE CASCADE,
    
    -- Unique constraint for LinkedIn post ID per user
    CONSTRAINT unique_post_per_user UNIQUE ("userId", "postId")
);

-- Table for storing LinkedIn connections data
CREATE TABLE IF NOT EXISTS linkedin_connections (
    -- Primary key
    "id" BIGSERIAL PRIMARY KEY,
    
    -- Reference to user
    "userId" VARCHAR(128) NOT NULL,
    
    -- Connection identifiers
    "connectionId" VARCHAR(255) NOT NULL, -- LinkedIn connection URN
    
    -- Connection profile data
    "firstName" VARCHAR(255),
    "lastName" VARCHAR(255),
    "email" VARCHAR(255),
    "profileUrl" VARCHAR(500),
    "profilePictureUrl" VARCHAR(500),
    "headline" VARCHAR(500),
    "industry" VARCHAR(255),
    "location" VARCHAR(255),
    "companyName" VARCHAR(255),
    "position" VARCHAR(255),
    
    -- Connection metadata
    "connectedAt" TIMESTAMP WITH TIME ZONE,
    "mutualConnectionsCount" INTEGER DEFAULT 0,
    
    -- Sync metadata
    "syncedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_user_id_connections CHECK (LENGTH("userId") > 0),
    CONSTRAINT valid_connection_id CHECK (LENGTH("connectionId") > 0),
    
    -- Foreign key to main users table
    CONSTRAINT fk_linkedin_connections_user 
        FOREIGN KEY ("userId") REFERENCES hush_users("userId") 
        ON DELETE CASCADE,
    
    -- Unique constraint for LinkedIn connection ID per user
    CONSTRAINT unique_connection_per_user UNIQUE ("userId", "connectionId")
);

-- Create indexes for better query performance
-- LinkedIn accounts indexes
CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_email ON linkedin_accounts(email);
CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_connected ON linkedin_accounts("isConnected");
CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_last_sync ON linkedin_accounts("lastSyncAt");
CREATE INDEX IF NOT EXISTS idx_linkedin_accounts_profile_id ON linkedin_accounts("profileId");

-- LinkedIn posts indexes
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_user ON linkedin_posts("userId");
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_post_id ON linkedin_posts("postId");
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_author_id ON linkedin_posts("authorId");
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_published_at ON linkedin_posts("publishedAt");
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_author_name ON linkedin_posts("authorName");
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_text ON linkedin_posts USING GIN(to_tsvector('english', text));
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_sync_date ON linkedin_posts("syncedAt");

-- LinkedIn connections indexes
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_user ON linkedin_connections("userId");
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_connection_id ON linkedin_connections("connectionId");
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_name ON linkedin_connections("firstName", "lastName");
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_company ON linkedin_connections("companyName");
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_connected_at ON linkedin_connections("connectedAt");

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_linkedin_posts_user_published ON linkedin_posts("userId", "publishedAt" DESC);
CREATE INDEX IF NOT EXISTS idx_linkedin_connections_user_connected ON linkedin_connections("userId", "connectedAt" DESC);

-- Create updated_at triggers (reuse the function from Gmail tables)
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

-- Enable Row Level Security (RLS) - disabled for Firebase auth integration
ALTER TABLE linkedin_accounts DISABLE ROW LEVEL SECURITY;
ALTER TABLE linkedin_posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE linkedin_connections DISABLE ROW LEVEL SECURITY;

-- Add comments for documentation
COMMENT ON TABLE linkedin_accounts IS 'LinkedIn OAuth tokens and account information';
COMMENT ON COLUMN linkedin_accounts."userId" IS 'Firebase user ID, used as primary key';
COMMENT ON COLUMN linkedin_accounts."accessToken" IS 'OAuth access token for LinkedIn API';
COMMENT ON COLUMN linkedin_accounts."refreshToken" IS 'OAuth refresh token for token renewal';
COMMENT ON COLUMN linkedin_accounts."profileId" IS 'LinkedIn member ID';
COMMENT ON COLUMN linkedin_accounts."syncSettings" IS 'User sync preferences (data types, frequency, etc.)';

COMMENT ON TABLE linkedin_posts IS 'LinkedIn posts and activity data synced from user accounts';
COMMENT ON COLUMN linkedin_posts."postId" IS 'LinkedIn unique post URN identifier';
COMMENT ON COLUMN linkedin_posts."authorId" IS 'LinkedIn author URN identifier';
COMMENT ON COLUMN linkedin_posts."publishedAt" IS 'When the post was published (LinkedIn date)';
COMMENT ON COLUMN linkedin_posts."syncedAt" IS 'When this record was synced from LinkedIn';

COMMENT ON TABLE linkedin_connections IS 'LinkedIn connections data synced from user accounts';
COMMENT ON COLUMN linkedin_connections."connectionId" IS 'LinkedIn unique connection URN identifier';
COMMENT ON COLUMN linkedin_connections."connectedAt" IS 'When the connection was made (LinkedIn date)';
COMMENT ON COLUMN linkedin_connections."syncedAt" IS 'When this record was synced from LinkedIn';

