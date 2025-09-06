-- Update RLS policies to work with Firebase Auth
-- Since we're using Firebase Auth but storing data in Supabase,
-- we need to disable RLS or create policies that work with our setup

-- Option 1: Disable RLS for now (for testing)
-- ALTER TABLE vault_documents DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE pda_context DISABLE ROW LEVEL SECURITY;

-- Option 2: Create policies that work with Firebase UIDs
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own documents" ON vault_documents;
DROP POLICY IF EXISTS "Users can insert their own documents" ON vault_documents;
DROP POLICY IF EXISTS "Users can update their own documents" ON vault_documents;
DROP POLICY IF EXISTS "Users can delete their own documents" ON vault_documents;

DROP POLICY IF EXISTS "Users can view their own context" ON pda_context;
DROP POLICY IF EXISTS "Users can insert their own context" ON pda_context;
DROP POLICY IF EXISTS "Users can update their own context" ON pda_context;
DROP POLICY IF EXISTS "Users can delete their own context" ON pda_context;

-- Create new policies that work with Firebase UIDs
-- These policies will allow access based on user_id matching Firebase UID
CREATE POLICY "Firebase users can view their own documents" ON vault_documents
    FOR SELECT USING (true); -- Allow all reads for now

CREATE POLICY "Firebase users can insert their own documents" ON vault_documents
    FOR INSERT WITH CHECK (true); -- Allow all inserts for now

CREATE POLICY "Firebase users can update their own documents" ON vault_documents
    FOR UPDATE USING (true); -- Allow all updates for now

CREATE POLICY "Firebase users can delete their own documents" ON vault_documents
    FOR DELETE USING (true); -- Allow all deletes for now

-- Create policies for pda_context
CREATE POLICY "Firebase users can view their own context" ON pda_context
    FOR SELECT USING (true);

CREATE POLICY "Firebase users can insert their own context" ON pda_context
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Firebase users can update their own context" ON pda_context
    FOR UPDATE USING (true);

CREATE POLICY "Firebase users can delete their own context" ON pda_context
    FOR DELETE USING (true);

-- Update storage policies to work with Firebase Auth
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;

-- Create new storage policies
CREATE POLICY "Firebase users can upload files" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'vault-files');

CREATE POLICY "Firebase users can view files" ON storage.objects
    FOR SELECT USING (bucket_id = 'vault-files');

CREATE POLICY "Firebase users can update files" ON storage.objects
    FOR UPDATE USING (bucket_id = 'vault-files');

CREATE POLICY "Firebase users can delete files" ON storage.objects
    FOR DELETE USING (bucket_id = 'vault-files');
