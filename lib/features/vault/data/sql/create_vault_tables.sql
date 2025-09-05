-- Create vault_documents table for storing document metadata
CREATE TABLE IF NOT EXISTS vault_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    filename TEXT NOT NULL, -- This will store the Supabase Storage URL
    original_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    content JSONB DEFAULT '{}',
    is_processed BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pda_context table for storing separate context data (LinkedIn, Gmail, Vault)
CREATE TABLE IF NOT EXISTS pda_context (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    context_type TEXT NOT NULL, -- 'linkedin', 'gmail', 'vault'
    context JSONB NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, context_type)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vault_documents_user_id ON vault_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_vault_documents_upload_date ON vault_documents(upload_date DESC);
CREATE INDEX IF NOT EXISTS idx_vault_documents_is_active ON vault_documents(is_active);
CREATE INDEX IF NOT EXISTS idx_vault_documents_file_type ON vault_documents(file_type);

-- Create indexes for pda_context table
CREATE INDEX IF NOT EXISTS idx_pda_context_user_id ON pda_context(user_id);
CREATE INDEX IF NOT EXISTS idx_pda_context_type ON pda_context(context_type);
CREATE INDEX IF NOT EXISTS idx_pda_context_user_type ON pda_context(user_id, context_type);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_vault_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_vault_documents_updated_at
    BEFORE UPDATE ON vault_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_vault_documents_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE vault_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE pda_context ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for vault_documents
-- Users can only access their own documents
CREATE POLICY "Users can view their own documents" ON vault_documents
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own documents" ON vault_documents
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents" ON vault_documents
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents" ON vault_documents
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for pda_context
-- Users can only access their own context data
CREATE POLICY "Users can view their own context" ON pda_context
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own context" ON pda_context
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own context" ON pda_context
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own context" ON pda_context
    FOR DELETE USING (auth.uid() = user_id);

-- Create vault-files storage bucket (this needs to be done in Supabase Dashboard or via API)
-- The bucket should be created with the name 'vault-files'
-- You can create it using the Supabase Dashboard or with this SQL:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('vault-files', 'vault-files', true);

-- Create storage policies for the vault-files bucket
-- These policies ensure users can only access their own files
CREATE POLICY "Users can upload their own files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'vault-files' AND 
        auth.uid()::text = (storage.foldername(name))[2]
    );

CREATE POLICY "Users can view their own files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'vault-files' AND 
        auth.uid()::text = (storage.foldername(name))[2]
    );

CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'vault-files' AND 
        auth.uid()::text = (storage.foldername(name))[2]
    );

CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'vault-files' AND 
        auth.uid()::text = (storage.foldername(name))[2]
    );
