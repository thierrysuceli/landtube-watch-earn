-- Migration: Upsert admin profile for given user_id
-- Created at: 2025-10-15 10:10:00
-- Purpose: Insert profile if missing or update existing profile and set is_admin = true

-- Replace values if you want different display_name or balance
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

-- To apply: use Supabase SQL Editor or run `npx supabase db push` in your project repo
