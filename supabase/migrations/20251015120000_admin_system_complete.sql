-- Combined Migration: Admin System Complete Setup
-- Created at: 2025-10-15 11:00:00
-- Purpose: Apply all admin functionality in one step

-- =============================================================================
-- PART 1: Add is_admin column to profiles
-- =============================================================================

ALTER TABLE IF EXISTS public.profiles
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- =============================================================================
-- PART 2: Create/Update admin profile
-- =============================================================================

INSERT INTO public.profiles (
  user_id,
  email,
  display_name,
  balance,
  withdrawal_goal,
  daily_reviews_completed,
  total_reviews,
  current_streak,
  last_review_date,
  requires_password_change,
  created_at,
  updated_at,
  is_admin
) VALUES (
  '11ff1237-a42c-46a8-a368-71ae0786735d'::uuid,
  'admin@landtube.com',
  'Admin',
  0.00,
  1000.00,
  0,
  0,
  0,
  NULL,
  false,
  now(),
  now(),
  true
) ON CONFLICT (user_id) DO UPDATE
  SET
    email = EXCLUDED.email,
    display_name = EXCLUDED.display_name,
    is_admin = TRUE,
    updated_at = now();

-- =============================================================================
-- PART 3: Add is_blocked column and admin RLS policies
-- =============================================================================

-- Add is_blocked column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'is_blocked'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN is_blocked boolean DEFAULT false;
  END IF;
END $$;

-- Add display_name column if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'display_name'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN display_name text;
  END IF;
END $$;

-- =============================================================================
-- PART 4: Admin RLS Policies
-- =============================================================================

-- Admin policies for profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Admins can view all profiles'
  ) THEN
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
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Admins can update all profiles'
  ) THEN
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
  END IF;
END $$;

-- Admin policies for videos table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'videos' AND policyname = 'Admins can insert videos'
  ) THEN
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
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'videos' AND policyname = 'Admins can update videos'
  ) THEN
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
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'videos' AND policyname = 'Admins can delete videos'
  ) THEN
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
  END IF;
END $$;

-- Admin policies for reviews table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'reviews' AND policyname = 'Admins can view all reviews'
  ) THEN
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
  END IF;
END $$;

-- Admin policies for daily_video_lists table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'daily_video_lists' AND policyname = 'Admins can view all lists'
  ) THEN
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
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'daily_video_lists' AND policyname = 'Admins can update all lists'
  ) THEN
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
  END IF;
END $$;

-- =============================================================================
-- PART 5: Admin Functions
-- =============================================================================

-- Function to reset user password (admin only)
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

  -- Mark user for password change
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

-- Function to adjust user balance (admin only)
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

  RETURN json_build_object(
    'success', true,
    'new_balance', new_balance,
    'adjustment', adjustment_amount,
    'reason', adjustment_reason
  );
END;
$$;

-- Function to block/unblock user (admin only)
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

-- =============================================================================
-- PART 6: Admin Dashboard Statistics View
-- =============================================================================

CREATE OR REPLACE VIEW public.admin_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM public.profiles) as total_users,
  (SELECT COUNT(*) FROM public.profiles WHERE is_admin = true) as total_admins,
  (SELECT COUNT(*) FROM public.profiles WHERE is_blocked = true) as blocked_users,
  (SELECT COUNT(*) FROM public.videos) as total_videos,
  (SELECT COUNT(*) FROM public.videos WHERE is_active = true) as active_videos,
  (SELECT COUNT(*) FROM public.reviews) as total_reviews,
  (SELECT COUNT(*) FROM public.reviews WHERE completed_at >= CURRENT_DATE) as reviews_today,
  (SELECT COALESCE(SUM(balance), 0) FROM public.profiles) as total_balance_distributed;

-- Grant access to admin view
GRANT SELECT ON public.admin_dashboard_stats TO authenticated;

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Admin system setup complete!';
  RAISE NOTICE '📋 Next steps:';
  RAISE NOTICE '   1. Create auth user with email: admin@landtube.com';
  RAISE NOTICE '   2. Use UUID: 11ff1237-a42c-46a8-a368-71ae0786735d';
  RAISE NOTICE '   3. Restart admin dev server';
  RAISE NOTICE '   4. Login at http://localhost:3002';
END $$;
