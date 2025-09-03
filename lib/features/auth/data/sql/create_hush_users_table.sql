-- Create table for storing user data in Supabase
-- This table mirrors the Firebase HushUsers collection structure
-- Run this SQL in your Supabase dashboard to create the table

CREATE TABLE IF NOT EXISTS hush_users (
    -- Primary key using userId from Firebase for consistency
    "userId" VARCHAR(128) PRIMARY KEY,
    
    -- User information fields (matching Firebase structure)
    "email" VARCHAR(255),
    "fullName" VARCHAR(255),
    "phoneNumber" VARCHAR(20),
    "isActive" BOOLEAN DEFAULT true,
    
    -- Timestamp fields (using snake_case for SQL convention)
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Additional constraints
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK ("phoneNumber" IS NULL OR LENGTH("phoneNumber") >= 10),
    CONSTRAINT valid_user_id CHECK (LENGTH("userId") > 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_hush_users_email ON hush_users(email);
CREATE INDEX IF NOT EXISTS idx_hush_users_phone ON hush_users("phoneNumber");
CREATE INDEX IF NOT EXISTS idx_hush_users_created_at ON hush_users(created_at);
CREATE INDEX IF NOT EXISTS idx_hush_users_is_active ON hush_users("isActive");

-- Create updated_at trigger to automatically update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_hush_users_updated_at 
    BEFORE UPDATE ON hush_users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE hush_users ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read/write their own data
-- Note: You may need to adjust these policies based on your authentication setup
CREATE POLICY "Users can view their own data" ON hush_users
    FOR SELECT USING (auth.uid()::TEXT = "userId");

CREATE POLICY "Users can insert their own data" ON hush_users
    FOR INSERT WITH CHECK (auth.uid()::TEXT = "userId");

CREATE POLICY "Users can update their own data" ON hush_users
    FOR UPDATE USING (auth.uid()::TEXT = "userId");

-- Service role policy for server-side operations (bypasses RLS for service operations)
-- Since we use Firebase for auth and Supabase for data storage, we need service role access
CREATE POLICY "Service role can access all data" ON hush_users
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- For apps using Firebase auth with Supabase storage, disable RLS
-- and handle authorization at the application level
-- This is safer than using service role keys in client apps
ALTER TABLE hush_users DISABLE ROW LEVEL SECURITY;

-- Add comments for documentation
COMMENT ON TABLE hush_users IS 'User data table mirroring Firebase HushUsers collection';
COMMENT ON COLUMN hush_users."userId" IS 'Firebase user ID, used as primary key';
COMMENT ON COLUMN hush_users.email IS 'User email address';
COMMENT ON COLUMN hush_users."fullName" IS 'User full name';
COMMENT ON COLUMN hush_users."phoneNumber" IS 'User phone number with country code';
COMMENT ON COLUMN hush_users."isActive" IS 'Whether the user account is active';
COMMENT ON COLUMN hush_users.created_at IS 'Timestamp when record was created';
COMMENT ON COLUMN hush_users.updated_at IS 'Timestamp when record was last updated';
