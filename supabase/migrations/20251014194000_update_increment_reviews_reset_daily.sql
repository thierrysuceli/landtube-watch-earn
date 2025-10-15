-- Migration: Update increment_reviews to safely reset daily counter on new day
-- Created at: 2025-10-14 19:40:00
-- Purpose: Ensure daily_reviews_completed resets automatically when day changes

CREATE OR REPLACE FUNCTION public.increment_reviews(user_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  profile_last_review_date DATE;
BEGIN
  -- Read last_review_date once to keep logic consistent within the txn
  SELECT last_review_date INTO profile_last_review_date
  FROM public.profiles
  WHERE user_id = user_id_param;

  -- Update with reset logic for a new day
  UPDATE public.profiles
  SET 
    -- If first review (NULL) or a new day, start at 1; otherwise increment
    daily_reviews_completed = CASE 
      WHEN profile_last_review_date IS NULL THEN 1
      WHEN profile_last_review_date < CURRENT_DATE THEN 1
      ELSE daily_reviews_completed + 1 
    END,

    total_reviews = total_reviews + 1,
    balance = balance + 5.00,
    last_review_date = CURRENT_DATE,

    -- Streak logic remains intact
    current_streak = CASE
      WHEN profile_last_review_date = CURRENT_DATE - INTERVAL '1 day' THEN current_streak + 1
      WHEN profile_last_review_date = CURRENT_DATE THEN current_streak
      ELSE 1
    END
  WHERE user_id = user_id_param;
END;
$$;
