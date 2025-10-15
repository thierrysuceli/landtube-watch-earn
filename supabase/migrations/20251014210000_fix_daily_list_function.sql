-- Fix ambiguous column references in get_or_create_daily_list function
CREATE OR REPLACE FUNCTION public.get_or_create_daily_list(user_id_param UUID)
RETURNS TABLE (
  list_id UUID,
  video_ids UUID[],
  current_video_index INTEGER,
  videos_completed INTEGER,
  is_completed BOOLEAN,
  list_date DATE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_list_id UUID;
  v_video_ids UUID[];
  v_current_video_index INTEGER;
  v_videos_completed INTEGER;
  v_is_completed BOOLEAN;
  v_list_date DATE;
  v_available_videos UUID[];
  v_reviewed_video_ids UUID[];
BEGIN
  -- Check if there's a list for today
  SELECT 
    dvl.id, 
    dvl.video_ids, 
    dvl.current_video_index, 
    dvl.videos_completed, 
    dvl.is_completed,
    dvl.list_date
  INTO 
    v_list_id,
    v_video_ids,
    v_current_video_index,
    v_videos_completed,
    v_is_completed,
    v_list_date
  FROM public.daily_video_lists dvl
  WHERE dvl.user_id = user_id_param 
    AND dvl.list_date = CURRENT_DATE
  LIMIT 1;

  -- If list exists for today, return it
  IF FOUND THEN
    RETURN QUERY SELECT 
      v_list_id,
      v_video_ids,
      v_current_video_index,
      v_videos_completed,
      v_is_completed,
      v_list_date;
    RETURN;
  END IF;

  -- No list for today, create new one
  -- Get all videos this user has already reviewed (ever)
  SELECT ARRAY_AGG(r.video_id)
  INTO v_reviewed_video_ids
  FROM public.reviews r
  WHERE r.user_id = user_id_param;

  -- Get available videos (active, not reviewed by this user)
  -- Using subquery to ensure LIMIT is applied before aggregation
  SELECT ARRAY_AGG(sub.id)
  INTO v_available_videos
  FROM (
    SELECT v.id
    FROM public.videos v
    WHERE v.is_active = true
      AND (v_reviewed_video_ids IS NULL OR v.id != ALL(v_reviewed_video_ids))
    ORDER BY RANDOM()
    LIMIT 5
  ) sub;

  -- If not enough videos, raise exception
  IF v_available_videos IS NULL OR array_length(v_available_videos, 1) < 5 THEN
    RAISE EXCEPTION 'Not enough available videos for a new list';
  END IF;

  -- Insert new list
  INSERT INTO public.daily_video_lists (
    user_id,
    list_date,
    video_ids,
    current_video_index,
    videos_completed,
    is_completed
  ) VALUES (
    user_id_param,
    CURRENT_DATE,
    v_available_videos,
    0,
    0,
    false
  )
  RETURNING 
    daily_video_lists.id,
    daily_video_lists.video_ids,
    daily_video_lists.current_video_index,
    daily_video_lists.videos_completed,
    daily_video_lists.is_completed,
    daily_video_lists.list_date
  INTO 
    v_list_id,
    v_video_ids,
    v_current_video_index,
    v_videos_completed,
    v_is_completed,
    v_list_date;

  -- Return newly created list
  RETURN QUERY SELECT 
    v_list_id,
    v_video_ids,
    v_current_video_index,
    v_videos_completed,
    v_is_completed,
    v_list_date;
END;
$$;

-- Fix ambiguous column references in update_list_progress function
CREATE OR REPLACE FUNCTION public.update_list_progress(
  user_id_param UUID,
  video_index_param INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_list_id UUID;
  v_videos_completed INTEGER;
  v_current_video_index INTEGER;
  v_is_completed BOOLEAN;
  v_video_ids UUID[];
  v_new_videos_completed INTEGER;
  v_new_current_index INTEGER;
BEGIN
  -- Get today's list
  SELECT 
    dvl.id, 
    dvl.videos_completed, 
    dvl.current_video_index, 
    dvl.is_completed, 
    dvl.video_ids
  INTO 
    v_list_id,
    v_videos_completed,
    v_current_video_index,
    v_is_completed,
    v_video_ids
  FROM public.daily_video_lists dvl
  WHERE dvl.user_id = user_id_param 
    AND dvl.list_date = CURRENT_DATE
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active list found for today';
  END IF;

  -- If already completed, do nothing
  IF v_is_completed THEN
    RETURN true;
  END IF;

  -- Calculate new progress
  v_new_videos_completed := v_videos_completed + 1;
  v_new_current_index := LEAST(video_index_param + 1, array_length(v_video_ids, 1) - 1);

  -- Update list
  UPDATE public.daily_video_lists
  SET 
    videos_completed = v_new_videos_completed,
    current_video_index = v_new_current_index,
    is_completed = (v_new_videos_completed >= 5),
    updated_at = now()
  WHERE id = v_list_id;

  -- If list is now complete, increment daily_reviews_completed
  IF v_new_videos_completed >= 5 THEN
    -- Use existing increment_reviews function (it handles daily reset)
    PERFORM public.increment_reviews(user_id_param);
  END IF;

  RETURN true;
END;
$$;

-- Ensure permissions are set
GRANT EXECUTE ON FUNCTION public.get_or_create_daily_list(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_list_progress(UUID, INTEGER) TO authenticated;
