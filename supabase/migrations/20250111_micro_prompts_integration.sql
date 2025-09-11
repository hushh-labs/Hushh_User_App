-- Micro Prompts Integration Database Schema
-- Stores user micro-prompt interactions for gradual profile building
-- Follows clean architecture with proper foreign key constraints

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Micro Prompt Questions Table
-- Stores the predefined question bank
CREATE TABLE IF NOT EXISTS micro_prompt_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_text TEXT NOT NULL,
  category TEXT NOT NULL, -- 'identity', 'style', 'lifestyle', 'health', 'tech', 'preferences'
  question_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(question_order)
);

-- User Micro Prompt Responses Table
-- Stores user responses to micro-prompts
CREATE TABLE IF NOT EXISTS user_micro_prompt_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  question_id UUID NOT NULL, -- FK to micro_prompt_questions(id)
  response_text TEXT,
  response_type TEXT NOT NULL, -- 'answered', 'skipped', 'ask_later'
  asked_at TIMESTAMP WITH TIME ZONE NOT NULL,
  responded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraints
  CONSTRAINT fk_micro_prompt_responses_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  CONSTRAINT fk_micro_prompt_responses_question 
    FOREIGN KEY (question_id) REFERENCES micro_prompt_questions(id) ON DELETE CASCADE,
  
  UNIQUE("userId", question_id, asked_at)
);

-- User Micro Prompt Schedule Table
-- Tracks scheduling and timing for micro-prompts
CREATE TABLE IF NOT EXISTS user_micro_prompt_schedule (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  last_prompt_shown_at TIMESTAMP WITH TIME ZONE,
  next_prompt_scheduled_at TIMESTAMP WITH TIME ZONE,
  quiet_hours_start TIME DEFAULT '23:00:00', -- 11 PM
  quiet_hours_end TIME DEFAULT '07:00:00', -- 7 AM
  timezone TEXT DEFAULT 'UTC',
  is_prompts_enabled BOOLEAN DEFAULT TRUE,
  prompt_frequency_minutes INTEGER DEFAULT 30,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraint
  CONSTRAINT fk_micro_prompt_schedule_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  
  UNIQUE("userId")
);

-- User App State Table
-- Tracks current app state to avoid prompts during sensitive flows
CREATE TABLE IF NOT EXISTS user_app_state (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" VARCHAR(128) NOT NULL, -- Proper FK to hush_users."userId"
  current_screen TEXT,
  is_in_sensitive_flow BOOLEAN DEFAULT FALSE,
  sensitive_flow_type TEXT, -- 'login', 'onboarding', 'upload', 'payment'
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Proper foreign key constraint
  CONSTRAINT fk_user_app_state_user 
    FOREIGN KEY ("userId") REFERENCES hush_users("userId") ON DELETE CASCADE,
  
  UNIQUE("userId")
);

-- Insert predefined micro-prompt questions
INSERT INTO micro_prompt_questions (question_text, category, question_order) VALUES
-- Identity & Basics
('What''s your birthday?', 'identity', 1),
('Which city do you currently live in?', 'identity', 2),

-- Style & Shopping
('What''s your shoe size?', 'style', 3),
('What''s your favorite color?', 'style', 4),
('Do you prefer branded fashion or budget fashion?', 'style', 5),
('Do you shop more online or offline?', 'style', 6),
('What''s your usual monthly shopping budget?', 'style', 7),

-- Lifestyle & Habits
('Are you a morning person or night owl?', 'lifestyle', 8),
('How many hours do you usually sleep?', 'lifestyle', 9),
('Do you prefer coffee, tea, or neither?', 'lifestyle', 10),
('How often do you eat outside in a week?', 'lifestyle', 11),

-- Health & Fitness
('What''s your favorite fitness activity? (Walk, Gym, Yoga, None)', 'health', 12),
('Do you follow a strict diet? (Yes / No)', 'health', 13),
('Would you like daily wellness tips?', 'health', 14),

-- Tech & Apps
('Which social media apps do you use most?', 'tech', 15),
('Do you play mobile games? If yes, which ones?', 'tech', 16),
('Do you prefer watching videos or reading articles?', 'tech', 17),

-- Preferences & Personalization
('Do you like surprise product recommendations?', 'preferences', 18),
('Do you prefer light mode or dark mode?', 'preferences', 19),
('Would you like weekly insights about your habits?', 'preferences', 20);

-- Create indexes for optimal query performance
CREATE INDEX IF NOT EXISTS idx_micro_prompt_questions_category ON micro_prompt_questions(category);
CREATE INDEX IF NOT EXISTS idx_micro_prompt_questions_order ON micro_prompt_questions(question_order);
CREATE INDEX IF NOT EXISTS idx_micro_prompt_questions_active ON micro_prompt_questions(is_active);

CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_responses_user_id ON user_micro_prompt_responses("userId");
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_responses_question_id ON user_micro_prompt_responses(question_id);
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_responses_type ON user_micro_prompt_responses(response_type);
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_responses_asked_at ON user_micro_prompt_responses(asked_at);
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_responses_responded_at ON user_micro_prompt_responses(responded_at);

CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_schedule_user_id ON user_micro_prompt_schedule("userId");
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_schedule_next_prompt ON user_micro_prompt_schedule(next_prompt_scheduled_at);
CREATE INDEX IF NOT EXISTS idx_user_micro_prompt_schedule_enabled ON user_micro_prompt_schedule(is_prompts_enabled);

CREATE INDEX IF NOT EXISTS idx_user_app_state_user_id ON user_app_state("userId");
CREATE INDEX IF NOT EXISTS idx_user_app_state_sensitive_flow ON user_app_state(is_in_sensitive_flow);
CREATE INDEX IF NOT EXISTS idx_user_app_state_last_activity ON user_app_state(last_activity_at);

-- Disable Row Level Security for easier access (following existing pattern)
ALTER TABLE micro_prompt_questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_micro_prompt_responses DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_micro_prompt_schedule DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_app_state DISABLE ROW LEVEL SECURITY;

-- Add updated_at triggers for tables that have updated_at column
CREATE TRIGGER update_user_micro_prompt_schedule_updated_at 
    BEFORE UPDATE ON user_micro_prompt_schedule 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_app_state_updated_at 
    BEFORE UPDATE ON user_app_state 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_micro_prompt_questions_updated_at 
    BEFORE UPDATE ON micro_prompt_questions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions to authenticated users
GRANT ALL ON micro_prompt_questions TO authenticated;
GRANT ALL ON user_micro_prompt_responses TO authenticated;
GRANT ALL ON user_micro_prompt_schedule TO authenticated;
GRANT ALL ON user_app_state TO authenticated;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE micro_prompt_questions IS 'Predefined question bank for micro-prompts';
COMMENT ON TABLE user_micro_prompt_responses IS 'User responses to micro-prompt questions';
COMMENT ON TABLE user_micro_prompt_schedule IS 'Scheduling and timing configuration for user micro-prompts';
COMMENT ON TABLE user_app_state IS 'Current app state to avoid prompts during sensitive flows';

COMMENT ON COLUMN user_micro_prompt_responses.response_type IS 'Type of response: answered, skipped, ask_later';
COMMENT ON COLUMN user_micro_prompt_schedule.quiet_hours_start IS 'Start time for quiet hours (no prompts)';
COMMENT ON COLUMN user_micro_prompt_schedule.quiet_hours_end IS 'End time for quiet hours (no prompts)';
COMMENT ON COLUMN user_app_state.sensitive_flow_type IS 'Type of sensitive flow: login, onboarding, upload, payment';

-- Create view for getting next available question for a user
CREATE OR REPLACE VIEW user_next_micro_prompt AS
SELECT 
  u."userId",
  mpq.id as question_id,
  mpq.question_text,
  mpq.category,
  mpq.question_order,
  umps.last_prompt_shown_at,
  umps.next_prompt_scheduled_at,
  umps.quiet_hours_start,
  umps.quiet_hours_end,
  umps.timezone,
  umps.is_prompts_enabled,
  uas.is_in_sensitive_flow,
  uas.sensitive_flow_type
FROM hush_users u
LEFT JOIN user_micro_prompt_schedule umps ON u."userId" = umps."userId"
LEFT JOIN user_app_state uas ON u."userId" = uas."userId"
CROSS JOIN micro_prompt_questions mpq
WHERE mpq.is_active = TRUE
  AND NOT EXISTS (
    -- Exclude questions answered or skipped in last 7 days
    SELECT 1 FROM user_micro_prompt_responses umpr 
    WHERE umpr."userId" = u."userId" 
      AND umpr.question_id = mpq.id 
      AND umpr.asked_at > NOW() - INTERVAL '7 days'
      AND umpr.response_type IN ('answered', 'skipped')
  )
ORDER BY u."userId", mpq.question_order;

-- Create view for user profile insights based on responses
CREATE OR REPLACE VIEW user_micro_prompt_profile AS
SELECT 
  umpr."userId",
  mpq.category,
  COUNT(*) as total_questions_in_category,
  COUNT(CASE WHEN umpr.response_type = 'answered' THEN 1 END) as answered_questions,
  COUNT(CASE WHEN umpr.response_type = 'skipped' THEN 1 END) as skipped_questions,
  COUNT(CASE WHEN umpr.response_type = 'ask_later' THEN 1 END) as ask_later_questions,
  ROUND(
    COUNT(CASE WHEN umpr.response_type = 'answered' THEN 1 END) * 100.0 / 
    COUNT(*), 2
  ) as completion_percentage,
  json_agg(
    json_build_object(
      'question', mpq.question_text,
      'response', umpr.response_text,
      'response_type', umpr.response_type,
      'responded_at', umpr.responded_at
    ) ORDER BY mpq.question_order
  ) as responses
FROM user_micro_prompt_responses umpr
JOIN micro_prompt_questions mpq ON umpr.question_id = mpq.id
GROUP BY umpr."userId", mpq.category;

-- Migration completed successfully
-- All micro-prompts integration tables created with proper relationships,
-- indexes, foreign key constraints, and optimized views for profile building
