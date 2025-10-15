-- Fix: Remove recursive policies and create proper admin access
-- This migration fixes the infinite recursion issue

-- =============================================================================
-- STEP 1: Drop problematic recursive policies
-- =============================================================================

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can insert videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can update videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can delete videos" ON public.videos;
DROP POLICY IF EXISTS "Admins can view all reviews" ON public.reviews;
DROP POLICY IF EXISTS "Admins can view all lists" ON public.daily_video_lists;
DROP POLICY IF EXISTS "Admins can update all lists" ON public.daily_video_lists;

-- =============================================================================
-- STEP 2: Create helper function to check if user is admin (cached)
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
-- STEP 3: Create non-recursive admin policies using the helper function
-- =============================================================================

-- Profiles: Admins can see all profiles
CREATE POLICY "admin_view_all_profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (user_id = auth.uid()) OR (public.is_admin() = true)
  );

-- Profiles: Admins can update all profiles
CREATE POLICY "admin_update_all_profiles"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    (user_id = auth.uid()) OR (public.is_admin() = true)
  );

-- Videos: Admins can view all videos (everyone can too, but keeping it explicit)
CREATE POLICY "admin_view_all_videos"
  ON public.videos
  FOR SELECT
  TO authenticated
  USING (is_active = true OR public.is_admin() = true);

-- Videos: Admins can insert videos
CREATE POLICY "admin_insert_videos"
  ON public.videos
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin() = true);

-- Videos: Admins can update videos
CREATE POLICY "admin_update_videos"
  ON public.videos
  FOR UPDATE
  TO authenticated
  USING (public.is_admin() = true);

-- Videos: Admins can delete videos
CREATE POLICY "admin_delete_videos"
  ON public.videos
  FOR DELETE
  TO authenticated
  USING (public.is_admin() = true);

-- Reviews: Admins can view all reviews
CREATE POLICY "admin_view_all_reviews"
  ON public.reviews
  FOR SELECT
  TO authenticated
  USING (
    (user_id = auth.uid()) OR (public.is_admin() = true)
  );

-- Daily Video Lists: Admins can view all lists
CREATE POLICY "admin_view_all_lists"
  ON public.daily_video_lists
  FOR SELECT
  TO authenticated
  USING (
    (user_id = auth.uid()) OR (public.is_admin() = true)
  );

-- Daily Video Lists: Admins can update all lists
CREATE POLICY "admin_update_all_lists"
  ON public.daily_video_lists
  FOR UPDATE
  TO authenticated
  USING (
    (user_id = auth.uid()) OR (public.is_admin() = true)
  );

-- =============================================================================
-- STEP 4: Add missing youtube_url column to videos if not exists
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'videos' AND column_name = 'youtube_url'
  ) THEN
    ALTER TABLE public.videos ADD COLUMN youtube_url text;
  END IF;
END $$;

-- =============================================================================
-- SUCCESS MESSAGE
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Fixed infinite recursion in admin policies!';
  RAISE NOTICE '✅ Created is_admin() helper function';
  RAISE NOTICE '✅ All admin policies now use non-recursive checks';
  RAISE NOTICE '📋 You should now be able to:';
  RAISE NOTICE '   - View all users';
  RAISE NOTICE '   - Add/edit/delete videos';
  RAISE NOTICE '   - View all reviews and lists';
END $$;
