-- Create Missing Profile for User
-- Run this in your Supabase SQL Editor

-- First, check if the user exists in auth.users
SELECT id, email, created_at 
FROM auth.users 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- Then check if they have a profile
SELECT * FROM profiles 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- If no profile exists, create one
INSERT INTO profiles (id, username, display_name, created_at)
VALUES (
  'ee259cd4-b9b3-4a85-908e-075038be7dd5',
  'user_ee259cd4',
  'User ee259cd4',
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Verify the profile was created
SELECT * FROM profiles 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5'; 