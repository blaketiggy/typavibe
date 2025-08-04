-- Fix Database Schema - Run this in your Supabase SQL Editor
-- This will add missing columns and fix the profiles table

-- Step 1: Check current table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- Step 2: Add missing columns to profiles table if they don't exist
DO $$ 
BEGIN
    -- Add username column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'username'
    ) THEN
        ALTER TABLE profiles ADD COLUMN username TEXT UNIQUE;
        RAISE NOTICE 'Added username column to profiles table';
    ELSE
        RAISE NOTICE 'username column already exists';
    END IF;

    -- Add display_name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'display_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN display_name TEXT;
        RAISE NOTICE 'Added display_name column to profiles table';
    ELSE
        RAISE NOTICE 'display_name column already exists';
    END IF;

    -- Add bio column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'bio'
    ) THEN
        ALTER TABLE profiles ADD COLUMN bio TEXT;
        RAISE NOTICE 'Added bio column to profiles table';
    ELSE
        RAISE NOTICE 'bio column already exists';
    END IF;

    -- Add avatar_url column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
        RAISE NOTICE 'Added avatar_url column to profiles table';
    ELSE
        RAISE NOTICE 'avatar_url column already exists';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());
        RAISE NOTICE 'Added updated_at column to profiles table';
    ELSE
        RAISE NOTICE 'updated_at column already exists';
    END IF;
END $$;

-- Step 3: Create the user profile with proper username
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

-- Step 5: Check final table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position; 