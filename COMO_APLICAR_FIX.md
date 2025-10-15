# 🚀 GUIA PASSO A PASSO - Aplicar Fix do Reset Diário

## 📋 O QUE VOCÊ PRECISA FAZER (5 minutos)

Vou te guiar passo a passo para aplicar a correção no seu banco Supabase. É super simples!

---

## 🎯 PASSO 1: Abrir o Supabase

1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Clique no seu projeto **LandTube** (project ID: `lhosnclxjhbxjbnbktny`)

---

## 🎯 PASSO 2: Abrir o SQL Editor

1. No menu lateral esquerdo, clique em **"SQL Editor"** (ícone de código `</>`)
2. Clique em **"New query"** (botão verde no canto superior direito)

---

## 🎯 PASSO 3: Colar o Código

Copie e cole este código SQL no editor:

```sql
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
```

---

## 🎯 PASSO 4: Executar

1. Clique no botão **"Run"** (ou pressione `Ctrl + Enter`)
2. Aguarde alguns segundos
3. Você deve ver a mensagem: **"Success. No rows returned"**

✅ **PRONTO! A correção foi aplicada!**

---

## 🧪 PASSO 5: Testar (Opcional mas Recomendado)

### Teste Rápido - Verificar se a função existe:

No SQL Editor, execute:

```sql
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'increment_reviews';
```

Você deve ver a função listada.

### Teste Completo - Simular um novo dia:

**ATENÇÃO**: Só faça isso se quiser testar! Vai resetar seu contador de hoje.

```sql
-- 1. Ver estado atual
SELECT user_id, daily_reviews_completed, last_review_date, balance
FROM public.profiles
LIMIT 1;

-- 2. Simular que última review foi ontem
UPDATE public.profiles
SET last_review_date = CURRENT_DATE - INTERVAL '1 day',
    daily_reviews_completed = 5
WHERE user_id = 'SEU-USER-ID-AQUI';  -- Substitua pelo user_id da query acima

-- 3. Fazer uma "review" (vai resetar para 1)
SELECT public.increment_reviews('SEU-USER-ID-AQUI');  -- Substitua pelo mesmo user_id

-- 4. Verificar que resetou
SELECT user_id, daily_reviews_completed, last_review_date, balance
FROM public.profiles
WHERE user_id = 'SEU-USER-ID-AQUI';
```

**Resultado esperado:**
- `daily_reviews_completed` deve ser **1** (resetou!)
- `last_review_date` deve ser **hoje**
- `balance` deve ter aumentado **$5.00**

---

## ✅ CONFIRMAÇÃO VISUAL NO SEU SITE

Depois de aplicar:

1. Abra seu site LandTube
2. Faça login
3. Vá para o Dashboard
4. Você deve ver **"0/5"** ou **"X/5"** avaliações hoje
5. Tente fazer uma avaliação - deve funcionar normalmente!

**Amanhã (15/10/2025):**
- Quando você fizer login, o contador vai estar zerado automaticamente
- Você poderá fazer 5 novas avaliações! 🎉

---

## 🚨 SE DER ERRO

### Erro: "permission denied for function increment_reviews"
**Solução**: Você precisa estar logado como owner do projeto. Verifique se está usando a conta correta.

### Erro: "syntax error"
**Solução**: Certifique-se de copiar TODO o código, incluindo as linhas iniciais com `--`.

### Erro: "relation profiles does not exist"
**Solução**: Você está no projeto errado. Verifique se selecionou o projeto correto.

---

## 🎉 RESUMO

**O que você fez:**
- Atualizou a função `increment_reviews()` no banco de dados
- Agora ela reseta automaticamente `daily_reviews_completed` quando muda o dia
- Zero mudanças no frontend
- Zero mudanças na estrutura do banco

**O que mudou:**
- ✅ Usuários podem fazer 5 avaliações POR DIA (não mais apenas 5 na vida toda)
- ✅ Reset automático à meia-noite
- ✅ Tudo funciona de forma segura e isolada

---

## 📞 PRECISA DE AJUDA?

Se tiver qualquer dúvida ou erro, me avise! Posso:
- Te guiar com prints de tela
- Fazer um vídeo explicativo
- Executar via outro método
- Resolver qualquer problema que aparecer

**Está pronto para aplicar? Siga os 4 passos acima! 🚀**
