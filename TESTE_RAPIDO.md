# 🚀 TESTE RÁPIDO - 2 Minutos

## ✅ Verificação se Funcionou

Copie e cole estas 2 queries no SQL Editor do Supabase:

---

### 🔍 TESTE 1: A função foi atualizada?

```sql
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'increment_reviews';
```

**✅ PASSOU SE**: Você ver no resultado uma linha com:
```
WHEN profile_last_review_date < CURRENT_DATE THEN 1
```

**❌ FALHOU SE**: Não encontrar essa linha (função não foi atualizada)

---

### 🧪 TESTE 2: O reset funciona?

**ANTES de executar**: Substitua `'COLE-SEU-USER-ID-AQUI'` por um UUID real.

Para pegar seu user_id, execute primeiro:
```sql
SELECT user_id FROM public.profiles LIMIT 1;
```

Depois execute este teste completo:

```sql
-- Configurar: simular que última review foi ONTEM
UPDATE public.profiles
SET last_review_date = CURRENT_DATE - INTERVAL '1 day',
    daily_reviews_completed = 5
WHERE user_id = 'COLE-SEU-USER-ID-AQUI';

-- Ver ANTES
SELECT daily_reviews_completed, last_review_date 
FROM public.profiles 
WHERE user_id = 'COLE-SEU-USER-ID-AQUI';

-- Executar função (simula uma review hoje)
SELECT public.increment_reviews('COLE-SEU-USER-ID-AQUI');

-- Ver DEPOIS
SELECT daily_reviews_completed, last_review_date 
FROM public.profiles 
WHERE user_id = 'COLE-SEU-USER-ID-AQUI';
```

**✅ PASSOU SE**:
- `daily_reviews_completed` mudou de **5 para 1** (resetou!)
- `last_review_date` mudou para **hoje**

**❌ FALHOU SE**:
- `daily_reviews_completed` foi para **6** (não resetou)

---

## 🎯 RESULTADO

### ✅ Se os 2 testes PASSARAM:
**PERFEITO! Está funcionando!** 🎉

Agora:
- Usuários podem fazer 5 avaliações POR DIA
- Todo dia reseta automaticamente
- Seu site está 100% funcional

### ❌ Se algum teste FALHOU:
Me avise qual teste falhou e eu te ajudo a corrigir!

---

## 📱 TESTE EXTRA: No seu site

1. Abra seu site LandTube
2. Faça login
3. Vá em "Start Reviews"
4. Faça uma avaliação
5. Volte ao Dashboard
6. O contador deve ter aumentado

✅ **Funcionou!**
