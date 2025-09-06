-- Fix RLS policies for Firebase Auth + Supabase Storage setup
-- Run this in your Supabase SQL Editor

-- Option 1: Temporarily disable RLS for testing (RECOMMENDED FOR NOW)
ALTER TABLE vault_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE pda_context DISABLE ROW LEVEL SECURITY;

-- Disable RLS on storage.objects for vault-files bucket
-- This allows uploads without authentication issues
DROP POLICY IF EXISTS "Firebase users can upload files" ON storage.objects;
DROP POLICY IF EXISTS "Firebase users can view files" ON storage.objects;
DROP POLICY IF EXISTS "Firebase users can update files" ON storage.objects;
DROP POLICY IF EXISTS "Firebase users can delete files" ON storage.objects;

-- Create permissive storage policies for vault-files bucket
CREATE POLICY "Allow all vault-files operations" ON storage.objects
    FOR ALL USING (bucket_id = 'vault-files');

-- Alternative Option 2: If you want to keep RLS enabled, use these policies instead:
-- (Comment out the above and uncomment below)

-- CREATE POLICY "Allow vault-files uploads" ON storage.objects
--     FOR INSERT WITH CHECK (bucket_id = 'vault-files');

-- CREATE POLICY "Allow vault-files reads" ON storage.objects
--     FOR SELECT USING (bucket_id = 'vault-files');

-- CREATE POLICY "Allow vault-files updates" ON storage.objects
--     FOR UPDATE USING (bucket_id = 'vault-files');

-- CREATE POLICY "Allow vault-files deletes" ON storage.objects
--     FOR DELETE USING (bucket_id = 'vault-files');

-- CREATE POLICY "Allow vault document inserts" ON vault_documents
--     FOR INSERT WITH CHECK (true);

-- CREATE POLICY "Allow vault document reads" ON vault_documents
--     FOR SELECT USING (true);

-- CREATE POLICY "Allow vault document updates" ON vault_documents
--     FOR UPDATE USING (true);

-- CREATE POLICY "Allow vault document deletes" ON vault_documents
--     FOR DELETE USING (true);
