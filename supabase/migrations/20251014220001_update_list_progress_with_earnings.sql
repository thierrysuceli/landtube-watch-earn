-- Update update_list_progress to calculate and pass actual earnings
-- Created at: 2025-10-14 22:00:00
-- Purpose: Calculate total earnings from all 5 videos and pass to increment_reviews

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
  v_total_earnings DECIMAL(10,2);
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

  -- If list is now complete, calculate total earnings and increment reviews
  IF v_new_videos_completed >= 5 THEN
    -- Calculate total earnings from all videos in the list
    SELECT COALESCE(SUM(v.earning_amount), 0)
    INTO v_total_earnings
    FROM public.videos v
    WHERE v.id = ANY(v_video_ids);

    -- Use existing increment_reviews function with actual earnings
    PERFORM public.increment_reviews(user_id_param, v_total_earnings);
  END IF;

  RETURN true;
END;
$$;

-- Ensure permissions are set
GRANT EXECUTE ON FUNCTION public.update_list_progress(UUID, INTEGER) TO authenticated;
