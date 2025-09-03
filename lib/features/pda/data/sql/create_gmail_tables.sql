-- Create tables for storing Gmail data in Supabase
-- This replaces the Firebase Firestore collections for Gmail integration
-- 
-- IMPORTANT: Run create_hush_users_table.sql FIRST before running this script
-- These tables reference the main hush_users table via foreign keys
-- 
-- Run this SQL in your Supabase dashboard to create the tables

-- Table for storing Gmail OAuth tokens and account information
CREATE TABLE IF NOT EXISTS gmail_accounts (
    -- Primary key using userId from Firebase for consistency
    "userId" VARCHAR(128) PRIMARY KEY,
    
    -- Account connection status
    "isConnected" BOOLEAN DEFAULT false,
    "provider" VARCHAR(50) DEFAULT 'gmail',
    "email" VARCHAR(255),
    
    -- OAuth tokens (encrypted in production)
    "accessToken" TEXT,
    "refreshToken" TEXT,
    "idToken" TEXT,
    "scopes" TEXT[], -- Array of OAuth scopes
    
    -- Gmail-specific data
    "historyId" VARCHAR(255), -- For incremental sync
    "lastSyncAt" TIMESTAMP WITH TIME ZONE,
    "syncSettings" JSONB DEFAULT '{}', -- Store sync preferences
    
    -- Timestamp fields
    "connectedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_user_id CHECK (LENGTH("userId") > 0),
    CONSTRAINT valid_provider CHECK (provider IN ('gmail', 'outlook', 'yahoo')),
    
    -- Foreign key to main users table
    CONSTRAINT fk_gmail_accounts_user 
        FOREIGN KEY ("userId") REFERENCES hush_users("userId") 
        ON DELETE CASCADE
);

-- Table for storing Gmail email data
CREATE TABLE IF NOT EXISTS gmail_emails (
    -- Primary key
    "id" BIGSERIAL PRIMARY KEY,
    
    -- Reference to user
    "userId" VARCHAR(128) NOT NULL,
    
    -- Gmail message identifiers
    "messageId" VARCHAR(255) NOT NULL, -- Gmail message ID
    "threadId" VARCHAR(255) NOT NULL,  -- Gmail thread ID
    "historyId" VARCHAR(255),          -- Gmail history ID
    
    -- Email metadata
    "subject" TEXT,
    "fromEmail" VARCHAR(255),
    "fromName" VARCHAR(255),
    "toEmails" TEXT[], -- Array of recipient emails
    "ccEmails" TEXT[], -- Array of CC emails
    "bccEmails" TEXT[], -- Array of BCC emails
    
    -- Email content
    "bodyText" TEXT,
    "bodyHtml" TEXT,
    "snippet" TEXT, -- Gmail snippet
    
    -- Email properties
    "isRead" BOOLEAN DEFAULT false,
    "isImportant" BOOLEAN DEFAULT false,
    "isStarred" BOOLEAN DEFAULT false,
    "labels" TEXT[], -- Gmail labels
    "attachments" JSONB DEFAULT '[]', -- Attachment metadata
    
    -- Date fields
    "receivedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "sentAt" TIMESTAMP WITH TIME ZONE,
    
    -- Sync metadata
    "syncedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_user_id_emails CHECK (LENGTH("userId") > 0),
    CONSTRAINT valid_message_id CHECK (LENGTH("messageId") > 0),
    CONSTRAINT valid_thread_id CHECK (LENGTH("threadId") > 0),
    CONSTRAINT valid_received_at CHECK ("receivedAt" IS NOT NULL),
    
    -- Foreign key to main users table (not gmail_accounts to avoid dependency chain)
    CONSTRAINT fk_gmail_emails_user 
        FOREIGN KEY ("userId") REFERENCES hush_users("userId") 
        ON DELETE CASCADE,
    
    -- Unique constraint for Gmail message ID per user
    CONSTRAINT unique_message_per_user UNIQUE ("userId", "messageId")
);

-- Create indexes for better query performance
-- Gmail accounts indexes
CREATE INDEX IF NOT EXISTS idx_gmail_accounts_email ON gmail_accounts(email);
CREATE INDEX IF NOT EXISTS idx_gmail_accounts_connected ON gmail_accounts("isConnected");
CREATE INDEX IF NOT EXISTS idx_gmail_accounts_last_sync ON gmail_accounts("lastSyncAt");

-- Gmail emails indexes
CREATE INDEX IF NOT EXISTS idx_gmail_emails_user ON gmail_emails("userId");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_message_id ON gmail_emails("messageId");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_thread_id ON gmail_emails("threadId");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_received_at ON gmail_emails("receivedAt");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_from_email ON gmail_emails("fromEmail");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_subject ON gmail_emails("subject");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_is_read ON gmail_emails("isRead");
CREATE INDEX IF NOT EXISTS idx_gmail_emails_labels ON gmail_emails USING GIN(labels);
CREATE INDEX IF NOT EXISTS idx_gmail_emails_sync_date ON gmail_emails("syncedAt");

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_gmail_emails_user_received ON gmail_emails("userId", "receivedAt" DESC);
CREATE INDEX IF NOT EXISTS idx_gmail_emails_user_thread ON gmail_emails("userId", "threadId");

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_gmail_accounts_updated_at 
    BEFORE UPDATE ON gmail_accounts 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gmail_emails_updated_at 
    BEFORE UPDATE ON gmail_emails 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS) - disabled for Firebase auth integration
ALTER TABLE gmail_accounts DISABLE ROW LEVEL SECURITY;
ALTER TABLE gmail_emails DISABLE ROW LEVEL SECURITY;

-- Add comments for documentation
COMMENT ON TABLE gmail_accounts IS 'Gmail OAuth tokens and account information';
COMMENT ON COLUMN gmail_accounts."userId" IS 'Firebase user ID, used as primary key';
COMMENT ON COLUMN gmail_accounts."accessToken" IS 'OAuth access token for Gmail API';
COMMENT ON COLUMN gmail_accounts."refreshToken" IS 'OAuth refresh token for token renewal';
COMMENT ON COLUMN gmail_accounts."historyId" IS 'Gmail history ID for incremental sync';
COMMENT ON COLUMN gmail_accounts."syncSettings" IS 'User sync preferences (duration, filters, etc.)';

COMMENT ON TABLE gmail_emails IS 'Gmail email data synced from user accounts';
COMMENT ON COLUMN gmail_emails."messageId" IS 'Gmail unique message identifier';
COMMENT ON COLUMN gmail_emails."threadId" IS 'Gmail thread identifier for conversation grouping';
COMMENT ON COLUMN gmail_emails."receivedAt" IS 'When the email was received (Gmail date)';
COMMENT ON COLUMN gmail_emails."syncedAt" IS 'When this record was synced from Gmail';
