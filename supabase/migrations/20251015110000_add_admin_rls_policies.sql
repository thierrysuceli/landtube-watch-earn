-- Migration: Add RLS policies for admin access
-- Created at: 2025-10-15 11:00:00
-- Purpose: Allow admins to view and manage all users data safely

-- Add admin policies for profiles table
CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Add admin policies for videos table
CREATE POLICY "Admins can insert videos"
  ON public.videos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can update videos"
  ON public.videos
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can delete videos"
  ON public.videos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Add admin policies for reviews table
CREATE POLICY "Admins can view all reviews"
  ON public.reviews
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Add admin policies for daily_video_lists table
CREATE POLICY "Admins can view all lists"
  ON public.daily_video_lists
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

CREATE POLICY "Admins can update all lists"
  ON public.daily_video_lists
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Create function to reset user password (admin only)
CREATE OR REPLACE FUNCTION public.admin_reset_user_password(
  target_user_id uuid,
  new_password text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_check boolean;
BEGIN
  -- Check if current user is admin
  SELECT is_admin INTO admin_check
  FROM public.profiles
  WHERE user_id = auth.uid();

  IF NOT COALESCE(admin_check, false) THEN
    RAISE EXCEPTION 'Only admins can reset passwords';
  END IF;

  -- Update password in auth.users (requires service role in practice)
  -- This is a placeholder - in production, use Supabase Admin API
  UPDATE public.profiles
  SET 
    requires_password_change = true,
    updated_at = now()
  WHERE user_id = target_user_id;

  RETURN json_build_object(
    'success', true,
    'message', 'User marked for password change'
  );
END;
$$;

-- Create function to adjust user balance (admin only)
CREATE OR REPLACE FUNCTION public.admin_adjust_balance(
  target_user_id uuid,
  adjustment_amount decimal(10,2),
  adjustment_reason text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_check boolean;
  new_balance decimal(10,2);
BEGIN
  -- Check if current user is admin
  SELECT is_admin INTO admin_check
  FROM public.profiles
  WHERE user_id = auth.uid();

  IF NOT COALESCE(admin_check, false) THEN
    RAISE EXCEPTION 'Only admins can adjust balances';
  END IF;

  -- Update balance
  UPDATE public.profiles
  SET 
    balance = balance + adjustment_amount,
    updated_at = now()
  WHERE user_id = target_user_id
  RETURNING balance INTO new_balance;

  -- Log the adjustment (you can create an audit table for this)
  -- For now, just return success

  RETURN json_build_object(
    'success', true,
    'new_balance', new_balance,
    'adjustment', adjustment_amount,
    'reason', adjustment_reason
  );
END;
$$;

-- Create function to block/unblock user (admin only)
CREATE OR REPLACE FUNCTION public.admin_toggle_user_block(
  target_user_id uuid,
  block_status boolean
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  admin_check boolean;
BEGIN
  -- Check if current user is admin
  SELECT is_admin INTO admin_check
  FROM public.profiles
  WHERE user_id = auth.uid();

  IF NOT COALESCE(admin_check, false) THEN
    RAISE EXCEPTION 'Only admins can block users';
  END IF;

  -- Add is_blocked column if doesn't exist
  ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_blocked boolean DEFAULT false;

  -- Update block status
  UPDATE public.profiles
  SET 
    is_blocked = block_status,
    updated_at = now()
  WHERE user_id = target_user_id;

  RETURN json_build_object(
    'success', true,
    'blocked', block_status
  );
END;
$$;

-- Add is_blocked column to profiles if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'is_blocked'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN is_blocked boolean DEFAULT false;
  END IF;
END $$;

-- Create view for admin dashboard statistics
CREATE OR REPLACE VIEW public.admin_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM public.profiles) as total_users,
  (SELECT COUNT(*) FROM public.profiles WHERE is_admin = true) as total_admins,
  (SELECT COUNT(*) FROM public.profiles WHERE is_blocked = true) as blocked_users,
  (SELECT COUNT(*) FROM public.videos) as total_videos,
  (SELECT COUNT(*) FROM public.videos WHERE is_active = true) as active_videos,
  (SELECT COUNT(*) FROM public.reviews) as total_reviews,
  (SELECT COUNT(*) FROM public.reviews WHERE created_at >= CURRENT_DATE) as reviews_today,
  (SELECT COALESCE(SUM(balance), 0) FROM public.profiles) as total_balance_distributed;

-- Grant access to admin view
GRANT SELECT ON public.admin_dashboard_stats TO authenticated;
