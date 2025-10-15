-- Create function to increment review counts and balance
CREATE OR REPLACE FUNCTION public.increment_reviews(user_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET 
    daily_reviews_completed = daily_reviews_completed + 1,
    total_reviews = total_reviews + 1,
    balance = balance + 5.00,
    last_review_date = CURRENT_DATE,
    current_streak = CASE
      WHEN last_review_date = CURRENT_DATE - INTERVAL '1 day' THEN current_streak + 1
      WHEN last_review_date = CURRENT_DATE THEN current_streak
      ELSE 1
    END
  WHERE user_id = user_id_param;
END;
$$;