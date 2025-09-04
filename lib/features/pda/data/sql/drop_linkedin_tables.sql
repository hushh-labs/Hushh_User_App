-- Drop all comprehensive LinkedIn tables that we can't populate due to API restrictions
-- Run this in Supabase SQL Editor to clean up

DROP TABLE IF EXISTS linkedin_messages;
DROP TABLE IF EXISTS linkedin_honors;
DROP TABLE IF EXISTS linkedin_volunteer_experience;
DROP TABLE IF EXISTS linkedin_courses;
DROP TABLE IF EXISTS linkedin_patents;
DROP TABLE IF EXISTS linkedin_publications;
DROP TABLE IF EXISTS linkedin_languages;
DROP TABLE IF EXISTS linkedin_certifications;
DROP TABLE IF EXISTS linkedin_skills;
DROP TABLE IF EXISTS linkedin_education;
DROP TABLE IF EXISTS linkedin_positions;
DROP TABLE IF EXISTS linkedin_connections;
DROP TABLE IF EXISTS linkedin_posts;
DROP TABLE IF EXISTS linkedin_accounts;

-- Clean up any indexes or triggers that might be left
DROP FUNCTION IF EXISTS update_updated_at_column();
