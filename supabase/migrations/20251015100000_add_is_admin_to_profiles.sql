-- Migration: Add is_admin column to profiles
-- Created at: 2025-10-15 10:00:00
-- Purpose: Add an is_admin flag to profiles so admin panel can check admin status

ALTER TABLE IF EXISTS public.profiles
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Optionally, set is_admin = true for an initial admin (replace with real user_id)
-- UPDATE public.profiles SET is_admin = true WHERE user_id = 'PUT_ADMIN_USER_ID_HERE';

-- Ensure RLS policies still allow users to read their own is_admin field
-- Existing policy "Users can view their own profile" already allows SELECT when user_id = auth.uid()
