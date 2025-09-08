-- Google Calendar Integration Database Schema
-- Extends Google Meet integration with calendar data for PDA context
-- Follows clean architecture with proper foreign key constraints

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Google Calendar Events Table
-- Stores calendar events with Google Meet links for PDA context
CREATE TABLE IF NOT EXISTS google_calendar_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  google_event_id TEXT NOT NULL,
  calendar_id TEXT NOT NULL,
  summary TEXT NOT NULL,
  description TEXT,
  location TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  is_all_day BOOLEAN DEFAULT FALSE,
  status TEXT, -- confirmed, tentative, cancelled
  visibility TEXT, -- default, public, private
  recurrence_rule TEXT,
  google_meet_link TEXT, -- extracted meet.google.com URL
  organizer_email TEXT,
  organizer_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraint to hush_users
  CONSTRAINT fk_calendar_events_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  
  UNIQUE("userId", google_event_id)
);

-- Google Calendar Attendees Table
-- Stores event participants for meeting context
CREATE TABLE IF NOT EXISTS google_calendar_attendees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  event_id UUID NOT NULL, -- FK to google_calendar_events(id)
  email TEXT NOT NULL,
  display_name TEXT,
  response_status TEXT, -- needsAction, declined, tentative, accepted
  is_organizer BOOLEAN DEFAULT FALSE,
  is_optional BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraints
  CONSTRAINT fk_calendar_attendees_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  CONSTRAINT fk_calendar_attendees_event 
    FOREIGN KEY (event_id) REFERENCES google_calendar_events(id) ON DELETE CASCADE
);

-- Google Meet Calendar Links Table
-- Bridge table linking calendar events to actual meet conferences
CREATE TABLE IF NOT EXISTS google_meet_calendar_links (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  calendar_event_id UUID NOT NULL, -- FK to google_calendar_events(id)
  meet_conference_id UUID NOT NULL, -- FK to google_meet_conferences(id)
  correlation_confidence DECIMAL(3,2), -- 0.00 to 1.00 confidence score
  correlation_method TEXT, -- 'meet_link', 'time_match', 'participant_match'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraints
  CONSTRAINT fk_calendar_links_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  CONSTRAINT fk_calendar_links_event 
    FOREIGN KEY (calendar_event_id) REFERENCES google_calendar_events(id) ON DELETE CASCADE,
  CONSTRAINT fk_calendar_links_conference 
    FOREIGN KEY (meet_conference_id) REFERENCES google_meet_conferences(id) ON DELETE CASCADE,
  
  UNIQUE(calendar_event_id, meet_conference_id)
);

-- Add calendar-related columns to existing google_meet_conferences table
ALTER TABLE google_meet_conferences 
ADD COLUMN IF NOT EXISTS calendar_event_id UUID, -- References google_calendar_events(id)
ADD COLUMN IF NOT EXISTS is_scheduled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS scheduled_start_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS scheduled_end_time TIMESTAMP WITH TIME ZONE;

-- Create indexes for optimal query performance
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_user_id ON google_calendar_events("userId");
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_start_time ON google_calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_end_time ON google_calendar_events(end_time);
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_google_meet_link ON google_calendar_events(google_meet_link);
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_google_event_id ON google_calendar_events(google_event_id);
CREATE INDEX IF NOT EXISTS idx_google_calendar_events_status ON google_calendar_events(status);

CREATE INDEX IF NOT EXISTS idx_google_calendar_attendees_user_id ON google_calendar_attendees("userId");
CREATE INDEX IF NOT EXISTS idx_google_calendar_attendees_event_id ON google_calendar_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_google_calendar_attendees_email ON google_calendar_attendees(email);
CREATE INDEX IF NOT EXISTS idx_google_calendar_attendees_response_status ON google_calendar_attendees(response_status);

CREATE INDEX IF NOT EXISTS idx_google_meet_calendar_links_user_id ON google_meet_calendar_links("userId");
CREATE INDEX IF NOT EXISTS idx_google_meet_calendar_links_calendar_event_id ON google_meet_calendar_links(calendar_event_id);
CREATE INDEX IF NOT EXISTS idx_google_meet_calendar_links_meet_conference_id ON google_meet_calendar_links(meet_conference_id);
CREATE INDEX IF NOT EXISTS idx_google_meet_calendar_links_correlation_confidence ON google_meet_calendar_links(correlation_confidence);

-- Add indexes to existing google_meet_conferences for calendar correlation
CREATE INDEX IF NOT EXISTS idx_google_meet_conferences_calendar_event_id ON google_meet_conferences(calendar_event_id);
CREATE INDEX IF NOT EXISTS idx_google_meet_conferences_is_scheduled ON google_meet_conferences(is_scheduled);
CREATE INDEX IF NOT EXISTS idx_google_meet_conferences_scheduled_start_time ON google_meet_conferences(scheduled_start_time);

-- Disable Row Level Security for easier access (following existing pattern)
ALTER TABLE google_calendar_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE google_calendar_attendees DISABLE ROW LEVEL SECURITY;
ALTER TABLE google_meet_calendar_links DISABLE ROW LEVEL SECURITY;

-- Add updated_at triggers for tables that have updated_at column
CREATE TRIGGER update_google_calendar_events_updated_at 
    BEFORE UPDATE ON google_calendar_events 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions to authenticated users
GRANT ALL ON google_calendar_events TO authenticated;
GRANT ALL ON google_calendar_attendees TO authenticated;
GRANT ALL ON google_meet_calendar_links TO authenticated;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE google_calendar_events IS 'Stores Google Calendar events with Meet links for PDA context';
COMMENT ON TABLE google_calendar_attendees IS 'Stores calendar event participants for meeting context analysis';
COMMENT ON TABLE google_meet_calendar_links IS 'Links calendar events to actual meet conferences for correlation';

COMMENT ON COLUMN google_calendar_events."userId" IS 'Foreign key to hush_users table';
COMMENT ON COLUMN google_calendar_events.google_meet_link IS 'Extracted Google Meet URL from event';
COMMENT ON COLUMN google_calendar_attendees.response_status IS 'Attendee response: needsAction, declined, tentative, accepted';
COMMENT ON COLUMN google_meet_calendar_links.correlation_confidence IS 'Confidence score (0.00-1.00) for event-meeting correlation';
COMMENT ON COLUMN google_meet_calendar_links.correlation_method IS 'Method used for correlation: meet_link, time_match, participant_match';

-- Create view for PDA context queries (optimized for fast access)
CREATE OR REPLACE VIEW pda_meeting_context AS
SELECT 
  gce.id as event_id,
  gce."userId",
  gce.summary,
  gce.description,
  gce.start_time,
  gce.end_time,
  gce.google_meet_link,
  gce.organizer_email,
  gce.organizer_name,
  gce.status as event_status,
  
  -- Attendee information (aggregated)
  COALESCE(
    (SELECT json_agg(
      json_build_object(
        'email', gca.email,
        'display_name', gca.display_name,
        'response_status', gca.response_status,
        'is_organizer', gca.is_organizer
      )
    ) FROM google_calendar_attendees gca WHERE gca.event_id = gce.id),
    '[]'::json
  ) as attendees,
  
  -- Linked conference information
  gmc.id as conference_id,
  gmc.conference_name,
  gmc.start_time as actual_start_time,
  gmc.end_time as actual_end_time,
  gmc.participant_count as actual_participant_count,
  gmc.was_recorded,
  gmc.was_transcribed,
  
  -- Correlation information
  gmcl.correlation_confidence,
  gmcl.correlation_method,
  
  -- Meeting status classification
  CASE 
    WHEN gce.start_time > NOW() THEN 'upcoming'
    WHEN gce.end_time < NOW() AND gmc.id IS NOT NULL THEN 'completed'
    WHEN gce.end_time < NOW() AND gmc.id IS NULL THEN 'missed'
    WHEN gce.start_time <= NOW() AND gce.end_time >= NOW() THEN 'ongoing'
    ELSE 'unknown'
  END as meeting_status

FROM google_calendar_events gce
LEFT JOIN google_meet_calendar_links gmcl ON gce.id = gmcl.calendar_event_id
LEFT JOIN google_meet_conferences gmc ON gmcl.meet_conference_id = gmc.id
WHERE gce.google_meet_link IS NOT NULL; -- Only events with Google Meet links

-- Create index on the view for faster PDA queries
CREATE INDEX IF NOT EXISTS idx_pda_meeting_context_user_start_time 
ON google_calendar_events("userId", start_time) 
WHERE google_meet_link IS NOT NULL;

-- Migration completed successfully
-- All Google Calendar integration tables created with proper relationships,
-- indexes, foreign key constraints, and optimized views for PDA context
