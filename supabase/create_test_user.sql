-- ============================================
-- Script para criar usuário teste no LandTube
-- ============================================
-- Execute este script no SQL Editor do Supabase Dashboard

-- IMPORTANTE: Substitua 'SEU_USER_ID_AQUI' por um UUID válido ou use gen_random_uuid()
-- Você pode gerar um UUID em: https://www.uuidgenerator.net/

-- Opção 1: Criar usuário na tabela auth.users (requer permissões de admin no Supabase)
-- Este método cria um usuário completo com autenticação

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(), -- ID do usuário (será gerado automaticamente)
  'authenticated',
  'authenticated',
  'teste@landtube.com', -- EMAIL DO TESTE
  crypt('senha123', gen_salt('bf')), -- SENHA: senha123
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
);

-- Agora pegue o UUID gerado e use abaixo
-- Para pegar o UUID do usuário criado, execute:
-- SELECT id, email FROM auth.users WHERE email = 'teste@landtube.com';

-- ============================================
-- Opção 2: MÉTODO MAIS SIMPLES (RECOMENDADO)
-- ============================================
-- Se a Opção 1 não funcionar, use este método:
-- 1. Vá em Authentication > Users no Dashboard do Supabase
-- 2. Clique em "Add User" > "Create new user"
-- 3. Email: teste@landtube.com
-- 4. Password: senha123
-- 5. Copie o UUID do usuário criado
-- 6. Execute o INSERT abaixo substituindo o UUID:

-- Depois de criar o usuário no dashboard, crie o perfil:
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
  requires_password_change
) VALUES (
  'COLE_O_UUID_DO_USUARIO_AQUI'::uuid, -- Substitua pelo UUID do usuário criado
  'teste@landtube.com',
  'Usuário Teste',
  0.00,
  1000.00,
  0,
  0,
  0,
  NULL,
  false -- false = não precisa trocar senha, true = precisa trocar senha
);

-- ============================================
-- Opção 3: SCRIPT COMPLETO AUTOMÁTICO
-- ============================================
-- Este script cria tudo de uma vez (pode precisar de permissões especiais)

DO $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Gera um novo UUID para o usuário
  new_user_id := gen_random_uuid();
  
  -- Tenta inserir na tabela auth.users
  BEGIN
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      new_user_id,
      'authenticated',
      'authenticated',
      'teste@landtube.com',
      crypt('senha123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
    
    RAISE NOTICE 'Usuário criado com UUID: %', new_user_id;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erro ao criar usuário na tabela auth: %', SQLERRM;
    RAISE NOTICE 'Use a Opção 2 (criar via Dashboard)';
  END;
  
  -- Cria o perfil
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
    requires_password_change
  ) VALUES (
    new_user_id,
    'teste@landtube.com',
    'Usuário Teste',
    0.00,
    1000.00,
    0,
    0,
    0,
    NULL,
    false
  );
  
  RAISE NOTICE 'Perfil criado com sucesso!';
  RAISE NOTICE 'Email: teste@landtube.com';
  RAISE NOTICE 'Senha: senha123';
END $$;

-- ============================================
-- Verificar se o usuário foi criado
-- ============================================
SELECT 
  u.id,
  u.email,
  u.created_at,
  p.display_name,
  p.balance
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.user_id
WHERE u.email = 'teste@landtube.com';

-- ============================================
-- CREDENCIAIS DO USUÁRIO TESTE
-- ============================================
-- Email: teste@landtube.com
-- Senha: senha123
-- ============================================
