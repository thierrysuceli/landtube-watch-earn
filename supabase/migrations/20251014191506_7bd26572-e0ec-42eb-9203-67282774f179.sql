-- Create profiles table for user data
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  email TEXT NOT NULL,
  display_name TEXT,
  balance DECIMAL(10,2) DEFAULT 0.00,
  withdrawal_goal DECIMAL(10,2) DEFAULT 1000.00,
  daily_reviews_completed INTEGER DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  last_review_date DATE,
  requires_password_change BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create videos table
CREATE TABLE public.videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  thumbnail_url TEXT,
  duration INTEGER DEFAULT 30,
  earning_amount DECIMAL(10,2) DEFAULT 5.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create reviews table
CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  video_id UUID NOT NULL REFERENCES public.videos(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  earning_amount DECIMAL(10,2) NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(user_id, video_id)
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (user_id = auth.uid()::uuid);

-- Videos policies (all users can view active videos)
CREATE POLICY "Anyone can view active videos"
  ON public.videos FOR SELECT
  USING (is_active = true);

-- Reviews policies
CREATE POLICY "Users can view their own reviews"
  ON public.reviews FOR SELECT
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can insert their own reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (user_id = auth.uid()::uuid);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to profiles
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Insert sample videos
INSERT INTO public.videos (title, thumbnail_url, duration, earning_amount) VALUES
  ('Vídeo Motivacional Incrível', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 30, 5.00),
  ('Tutorial de Programação', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 45, 5.00),
  ('Melhores Momentos de Esportes', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 60, 5.00),
  ('Documentário sobre a Natureza', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 90, 5.00),
  ('Aula de Culinária Rápida', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 30, 5.00);