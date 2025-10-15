-- Create daily_video_lists table to persist daily video queues
CREATE TABLE public.daily_video_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  list_date DATE NOT NULL DEFAULT CURRENT_DATE,
  video_ids UUID[] NOT NULL, -- Array of 5 video UUIDs
  current_video_index INTEGER DEFAULT 0, -- Which video user is watching (0-4)
  videos_completed INTEGER DEFAULT 0, -- How many videos finished (0-5)
  is_completed BOOLEAN DEFAULT false, -- If all 5 videos are done
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  -- Ensure one active list per user per day
  UNIQUE(user_id, list_date)
);

-- Enable RLS
ALTER TABLE public.daily_video_lists ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own lists"
  ON public.daily_video_lists FOR SELECT
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can insert their own lists"
  ON public.daily_video_lists FOR INSERT
  WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own lists"
  ON public.daily_video_lists FOR UPDATE
  USING (user_id = auth.uid()::uuid);

-- Add updated_at trigger
CREATE TRIGGER set_daily_video_lists_updated_at
  BEFORE UPDATE ON public.daily_video_lists
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Create index for faster queries
CREATE INDEX idx_daily_video_lists_user_date ON public.daily_video_lists(user_id, list_date);

-- Function to get or create daily video list
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
  existing_list RECORD;
  available_videos UUID[];
  reviewed_video_ids UUID[];
BEGIN
  -- Check if there's a list for today
  SELECT 
    id, 
    daily_video_lists.video_ids, 
    current_video_index, 
    videos_completed, 
    is_completed,
    daily_video_lists.list_date
  INTO existing_list
  FROM public.daily_video_lists
  WHERE user_id = user_id_param 
    AND list_date = CURRENT_DATE
  LIMIT 1;

  -- If list exists for today, return it
  IF FOUND THEN
    RETURN QUERY SELECT 
      existing_list.id,
      existing_list.video_ids,
      existing_list.current_video_index,
      existing_list.videos_completed,
      existing_list.is_completed,
      existing_list.list_date;
    RETURN;
  END IF;

  -- No list for today, create new one
  -- Get all videos this user has already reviewed (ever)
  SELECT ARRAY_AGG(video_id)
  INTO reviewed_video_ids
  FROM public.reviews
  WHERE reviews.user_id = user_id_param;

  -- Get available videos (active, not reviewed by this user)
  SELECT ARRAY_AGG(v.id ORDER BY RANDOM())
  INTO available_videos
  FROM public.videos v
  WHERE v.is_active = true
    AND (reviewed_video_ids IS NULL OR v.id != ALL(reviewed_video_ids))
  LIMIT 5;

  -- If not enough videos, raise exception
  IF available_videos IS NULL OR array_length(available_videos, 1) < 5 THEN
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
    available_videos,
    0,
    0,
    false
  )
  RETURNING 
    id,
    daily_video_lists.video_ids,
    current_video_index,
    videos_completed,
    is_completed,
    list_date
  INTO existing_list;

  -- Return newly created list
  RETURN QUERY SELECT 
    existing_list.id,
    existing_list.video_ids,
    existing_list.current_video_index,
    existing_list.videos_completed,
    existing_list.is_completed,
    existing_list.list_date;
END;
$$;

-- Function to update list progress after watching a video
CREATE OR REPLACE FUNCTION public.update_list_progress(
  user_id_param UUID,
  video_index_param INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  list_record RECORD;
  new_videos_completed INTEGER;
  new_current_index INTEGER;
BEGIN
  -- Get today's list
  SELECT id, videos_completed, current_video_index, is_completed, video_ids
  INTO list_record
  FROM public.daily_video_lists
  WHERE user_id = user_id_param 
    AND list_date = CURRENT_DATE
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active list found for today';
  END IF;

  -- If already completed, do nothing
  IF list_record.is_completed THEN
    RETURN true;
  END IF;

  -- Calculate new progress
  new_videos_completed := list_record.videos_completed + 1;
  new_current_index := LEAST(video_index_param + 1, array_length(list_record.video_ids, 1) - 1);

  -- Update list
  UPDATE public.daily_video_lists
  SET 
    videos_completed = new_videos_completed,
    current_video_index = new_current_index,
    is_completed = (new_videos_completed >= 5),
    updated_at = now()
  WHERE id = list_record.id;

  -- If list is now complete, increment daily_reviews_completed
  IF new_videos_completed >= 5 THEN
    -- Use existing increment_reviews function (it handles daily reset)
    PERFORM public.increment_reviews(user_id_param);
  END IF;

  RETURN true;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_or_create_daily_list(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_list_progress(UUID, INTEGER) TO authenticated;
