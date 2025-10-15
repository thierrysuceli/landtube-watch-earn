-- ============================================
-- SQL para Adicionar 6 Vídeos ao Banco
-- ============================================
-- Execute este script no SQL Editor do Supabase Dashboard

-- Limpar vídeos antigos se necessário (OPCIONAL - COMENTE SE NÃO QUISER)
-- DELETE FROM public.videos WHERE youtube_url IS NULL;

-- Adicionar 6 novos vídeos ao banco
INSERT INTO public.videos (
  title,
  thumbnail_url,
  youtube_url,
  duration,
  earning_amount,
  is_active
) VALUES 
(
  'Motivação para Seus Objetivos',
  'https://img.youtube.com/vi/ZXsQAXx_ao0/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=ZXsQAXx_ao0',
  30,
  5.00,
  true
),
(
  'Dica Rápida de Produtividade',
  'https://img.youtube.com/vi/W0ny5-LWEwk/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=W0ny5-LWEwk',
  30,
  5.00,
  true
),
(
  'Fato Incrível sobre Tecnologia',
  'https://img.youtube.com/vi/bBC-nXj3Ng4/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=bBC-nXj3Ng4',
  30,
  5.00,
  true
),
(
  'Momento Inspirador do Dia',
  'https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=9bZkp7q19f0',
  30,
  5.00,
  true
),
(
  'Curiosidade Científica',
  'https://img.youtube.com/vi/tlTKTTt47WE/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=tlTKTTt47WE',
  30,
  5.00,
  true
),
(
  'Lição de Vida em 30 Segundos',
  'https://img.youtube.com/vi/L2c2aU9T03A/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=L2c2aU9T03A',
  30,
  5.00,
  true
);

-- ============================================
-- Verificar os vídeos cadastrados
-- ============================================
SELECT 
  id,
  title,
  youtube_url,
  duration,
  earning_amount,
  is_active,
  created_at
FROM public.videos
ORDER BY created_at DESC;

-- ============================================
-- EXTRA: Como adicionar seus próprios vídeos
-- ============================================
-- Template para adicionar novos vídeos:
/*
INSERT INTO public.videos (
  title,
  thumbnail_url,
  youtube_url,
  duration,
  earning_amount,
  is_active
) VALUES (
  'Título do Vídeo',
  'https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg',
  'https://www.youtube.com/watch?v=VIDEO_ID',
  30,  -- duração em segundos
  5.00,  -- valor ganho
  true
);
*/

-- ============================================
-- Como pegar o ID do vídeo do YouTube:
-- ============================================
-- URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
--                                      ^^^^^^^^^ <- Este é o ID
-- 
-- Para thumbnail: https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg
-- Substitua VIDEO_ID pelo ID do vídeo
-- ============================================
