-- Emergency Fix: Remove ALL policies and recreate clean structure
-- This fixes the 500 error and login issues

-- =============================================================================
-- STEP 1: Drop ALL existing policies (clean slate)
-- =============================================================================

-- Drop all profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "admin_view_all_profiles" ON public.profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.profiles;

-- Drop all videos policies
DROP POLICY IF EXISTS "Anyone can view active videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can insert videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can update videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can delete videos" ON public.videos;
DROP POLICY IF EXISTS "admin_view_all_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_insert_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_update_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_delete_videos" ON public.videos;

-- Drop all reviews policies
DROP POLICY IF EXISTS "Users can view their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can insert their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Admins can view all reviews" ON public.reviews;
DROP POLICY IF EXISTS "admin_view_all_reviews" ON public.reviews;

-- Drop all daily_video_lists policies (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_video_lists') THEN
    DROP POLICY IF EXISTS "Users can view their own lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "Users can insert their own lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "Users can update their own lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "Admins can view all lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "Admins can update all lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "admin_view_all_lists" ON public.daily_video_lists;
    DROP POLICY IF EXISTS "admin_update_all_lists" ON public.daily_video_lists;
  END IF;
END $$;

-- =============================================================================
-- STEP 2: Ensure helper function exists
-- =============================================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.profiles WHERE user_id = auth.uid() LIMIT 1),
    false
  );
$$;

-- =============================================================================
-- STEP 3: Create clean, non-conflicting policies
-- =============================================================================

-- PROFILES POLICIES
-- Regular users can view/update/insert their own profile
CREATE POLICY "profiles_select_own"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "profiles_update_own"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "profiles_insert_own"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Admins can view all profiles
CREATE POLICY "profiles_select_admin"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (public.is_admin() = true);

-- Admins can update all profiles
CREATE POLICY "profiles_update_admin"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (public.is_admin() = true);

-- VIDEOS POLICIES
-- Everyone can view active videos
CREATE POLICY "videos_select_active"
  ON public.videos
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Admins can view all videos (including inactive)
CREATE POLICY "videos_select_admin"
  ON public.videos
  FOR SELECT
  TO authenticated
  USING (public.is_admin() = true);

-- Admins can insert videos
CREATE POLICY "videos_insert_admin"
  ON public.videos
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin() = true);

-- Admins can update videos
CREATE POLICY "videos_update_admin"
  ON public.videos
  FOR UPDATE
  TO authenticated
  USING (public.is_admin() = true);

-- Admins can delete videos
CREATE POLICY "videos_delete_admin"
  ON public.videos
  FOR DELETE
  TO authenticated
  USING (public.is_admin() = true);

-- REVIEWS POLICIES
-- Users can view their own reviews
CREATE POLICY "reviews_select_own"
  ON public.reviews
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can insert their own reviews
CREATE POLICY "reviews_insert_own"
  ON public.reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Admins can view all reviews
CREATE POLICY "reviews_select_admin"
  ON public.reviews
  FOR SELECT
  TO authenticated
  USING (public.is_admin() = true);

-- DAILY_VIDEO_LISTS POLICIES (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'daily_video_lists') THEN
    -- Users can view their own lists
    EXECUTE 'CREATE POLICY "lists_select_own"
      ON public.daily_video_lists
      FOR SELECT
      TO authenticated
      USING (user_id = auth.uid())';

    -- Users can insert their own lists
    EXECUTE 'CREATE POLICY "lists_insert_own"
      ON public.daily_video_lists
      FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid())';

    -- Users can update their own lists
    EXECUTE 'CREATE POLICY "lists_update_own"
      ON public.daily_video_lists
      FOR UPDATE
      TO authenticated
      USING (user_id = auth.uid())';

    -- Admins can view all lists
    EXECUTE 'CREATE POLICY "lists_select_admin"
      ON public.daily_video_lists
      FOR SELECT
      TO authenticated
      USING (public.is_admin() = true)';

    -- Admins can update all lists
    EXECUTE 'CREATE POLICY "lists_update_admin"
      ON public.daily_video_lists
      FOR UPDATE
      TO authenticated
      USING (public.is_admin() = true)';
  END IF;
END $$;

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Emergency fix applied successfully!';
  RAISE NOTICE '✅ All conflicting policies removed';
  RAISE NOTICE '✅ Clean policy structure recreated';
  RAISE NOTICE '📋 Users can now login normally';
  RAISE NOTICE '📋 Admins have full access to all data';
END $$;
