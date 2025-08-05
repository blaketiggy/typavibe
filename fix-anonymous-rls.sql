-- Fix RLS Policies for Anonymous Collections
-- Run this in your Supabase SQL Editor

-- First, let's check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('collections', 'collection_items')
ORDER BY tablename, policyname;

-- Drop existing policies for collections
DROP POLICY IF EXISTS "Public collections are viewable by everyone" ON collections;
DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
DROP POLICY IF EXISTS "Users can create collections" ON collections;
DROP POLICY IF EXISTS "Users can update their own collections" ON collections;

-- Drop existing policies for collection_items
DROP POLICY IF EXISTS "Items viewable if collection is viewable" ON collection_items;

-- Create new policies for collections
CREATE POLICY "anon_create_collections" ON collections
FOR INSERT WITH CHECK (is_anonymous = true);

CREATE POLICY "anon_read_collections" ON collections
FOR SELECT USING (is_anonymous = true AND is_public = true);

CREATE POLICY "user_read_collections" ON collections
FOR SELECT USING (is_public = true);

CREATE POLICY "user_create_collections" ON collections
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_update_collections" ON collections
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "user_delete_collections" ON collections
FOR DELETE USING (auth.uid() = user_id);

-- Create new policies for collection_items
CREATE POLICY "anon_read_collection_items" ON collection_items
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE is_anonymous = true AND is_public = true
  )
);

CREATE POLICY "user_read_collection_items" ON collection_items
FOR SELECT USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE is_public = true OR auth.uid() = user_id
  )
);

CREATE POLICY "user_create_collection_items" ON collection_items
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections 
    WHERE auth.uid() = user_id
  )
);

CREATE POLICY "user_update_collection_items" ON collection_items
FOR UPDATE USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE auth.uid() = user_id
  )
);

CREATE POLICY "user_delete_collection_items" ON collection_items
FOR DELETE USING (
  collection_id IN (
    SELECT id FROM collections 
    WHERE auth.uid() = user_id
  )
);

-- Allow anonymous users to insert items for anonymous collections
CREATE POLICY "anon_create_collection_items" ON collection_items
FOR INSERT WITH CHECK (
  collection_id IN (
    SELECT id FROM collections 
    WHERE is_anonymous = true
  )
);

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('collections', 'collection_items')
ORDER BY tablename, policyname; 