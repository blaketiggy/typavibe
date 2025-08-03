-- TypaVibe Database Schema
-- Run these commands in your Supabase SQL Editor

-- Step 1: Create Profiles Table (extends Supabase Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Step 2: Create Collections Table
CREATE TABLE collections (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NULL, -- Allow null for anonymous
  title TEXT NOT NULL,
  description TEXT,
  slug TEXT UNIQUE NOT NULL,
  is_public BOOLEAN DEFAULT true,
  is_anonymous BOOLEAN DEFAULT false,
  anon_session_id TEXT, -- For anonymous collections  
  tags TEXT[] DEFAULT '{}',
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMP WITH TIME ZONE -- Optional: auto-delete anonymous after 30 days
);

-- Step 3: Create Collection Items Table
CREATE TABLE collection_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  title TEXT,
  description TEXT,
  price DECIMAL(10,2),
  image_url TEXT,
  position INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_items ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS Policies

-- Collections policies
CREATE POLICY "Public collections are viewable by everyone"
ON collections FOR SELECT
USING (is_public = true);

CREATE POLICY "Users can view their own collections"
ON collections FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can create collections"
ON collections FOR INSERT
WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update their own collections"
ON collections FOR UPDATE
USING (auth.uid() = user_id);

-- Collection items inherit collection permissions
CREATE POLICY "Items viewable if collection is viewable"
ON collection_items FOR SELECT
USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE is_public = true OR auth.uid() = user_id
  )
);

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id); 