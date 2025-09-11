-- Fix micro prompts frequency to 2 minutes for testing
UPDATE user_micro_prompt_schedule 
SET 
  prompt_frequency_minutes = 2,
  updated_at = NOW()
WHERE "userId" = '8yalh8RyE2Q2SS5ddavfifzVS6W2';
