-- Fix User Profile and Username Issues
-- Run this in your Supabase SQL Editor

-- Step 1: Check if user exists in auth.users
SELECT id, email, created_at 
FROM auth.users 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- Step 2: Check if profile exists
SELECT * FROM profiles 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- Step 3: Create the profile with a proper username
INSERT INTO profiles (id, username, display_name, created_at)
VALUES (
  'ee259cd4-b9b3-4a85-908e-075038be7dd5',
  'blake',
  'Blake',
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  updated_at = NOW();

-- Step 4: Verify the profile was created
SELECT * FROM profiles 
WHERE id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- Step 5: Check if any collections exist for this user
SELECT * FROM collections 
WHERE user_id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5';

-- Step 6: If collections exist, update them to have proper user_id
UPDATE collections 
SET user_id = 'ee259cd4-b9b3-4a85-908e-075038be7dd5'
WHERE slug = 'finally' AND user_id IS NULL; 