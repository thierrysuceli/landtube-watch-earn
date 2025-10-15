# 🔍 ANÁLISE: Sistema de Reset Diário de Avaliações

## ⚠️ PROBLEMA IDENTIFICADO: **NÃO EXISTE RESET AUTOMÁTICO DIÁRIO**

---

## 📊 Situação Atual

### ✅ O que EXISTE:
1. **Campo no banco**: `daily_reviews_completed` (INTEGER)
2. **Campo de controle**: `last_review_date` (DATE)
3. **Verificação no frontend**: Bloqueia quando `daily_reviews_completed >= 5`
4. **Incremento funcionando**: Função `increment_reviews()` aumenta contador

### ❌ O que NÃO EXISTE:
1. **Nenhum mecanismo de reset automático**
2. **Nenhum CRON job ou scheduled task**
3. **Nenhum trigger de reset na meia-noite**
4. **Nenhuma verificação no frontend para resetar**

---

## 🔍 Análise Detalhada

### 1. **Database Schema (profiles table)**
```sql
daily_reviews_completed INTEGER DEFAULT 0,
last_review_date DATE,
```

✅ **Campos existem e funcionam**

---

### 2. **Função increment_reviews()**
**Arquivo**: `supabase/migrations/20251014191715_3ce80107-4024-4847-97ca-99b28790c8e3.sql`

```sql
CREATE OR REPLACE FUNCTION public.increment_reviews(user_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET 
    daily_reviews_completed = daily_reviews_completed + 1,  -- ✅ Incrementa
    total_reviews = total_reviews + 1,
    balance = balance + 5.00,
    last_review_date = CURRENT_DATE,  -- ✅ Atualiza data
    current_streak = CASE
      WHEN last_review_date = CURRENT_DATE - INTERVAL '1 day' THEN current_streak + 1
      WHEN last_review_date = CURRENT_DATE THEN current_streak
      ELSE 1
    END
  WHERE user_id = user_id_param;
END;
$$;
```

**Comportamento atual:**
- ✅ Incrementa `daily_reviews_completed`
- ✅ Atualiza `last_review_date` para CURRENT_DATE
- ✅ Gerencia streak corretamente
- ❌ **NÃO RESETA** o contador quando a data muda

---

### 3. **Frontend - Review.tsx (linha 57-65)**
```typescript
// Get user's profile to check daily reviews
const { data: profile } = await supabase
  .from("profiles")
  .select("daily_reviews_completed")
  .eq("user_id", session.user.id)
  .single();

if (profile && profile.daily_reviews_completed >= 5) {
  toast.info("You've already completed your daily reviews!");
  navigate("/dashboard");
  return;
}
```

**Comportamento:**
- ✅ Verifica se `daily_reviews_completed >= 5`
- ✅ Bloqueia acesso se limite atingido
- ❌ **NÃO VERIFICA** se é um novo dia

---

### 4. **Frontend - Dashboard.tsx**
```typescript
const { data: profileData, error } = await supabase
  .from("profiles")
  .select("*")
  .eq("user_id", session.user.id)
  .single();

setProfile(profileData);
```

**Comportamento:**
- ✅ Carrega dados do perfil
- ❌ **NÃO VERIFICA** se precisa resetar

---

## 🚨 CONSEQUÊNCIA DO PROBLEMA

### Cenário Real:
1. **Dia 1 (14/10/2025):**
   - Usuário faz 5 avaliações
   - `daily_reviews_completed = 5`
   - `last_review_date = '2025-10-14'`

2. **Dia 2 (15/10/2025):**
   - Usuário tenta fazer mais avaliações
   - Sistema verifica: `daily_reviews_completed = 5` ✅ (ainda é 5!)
   - **❌ BLOQUEADO PARA SEMPRE!**

3. **Resultado:**
   - Contador **NUNCA** reseta
   - Usuário pode fazer **APENAS 5 avaliações NA VIDA TODA**
   - Sistema travado após primeiro dia

---

## 💡 SOLUÇÕES POSSÍVEIS

### **Opção 1: Reset no Frontend (Recomendado)** ⭐
**Vantagens:**
- Implementação rápida
- Não requer alterações no banco
- Funciona imediatamente

**Implementação:**
Adicionar verificação em `Review.tsx` e `Dashboard.tsx`:

```typescript
// Verificar se é um novo dia e resetar
const shouldResetDaily = (lastReviewDate: string | null): boolean => {
  if (!lastReviewDate) return false;
  
  const lastDate = new Date(lastReviewDate);
  const today = new Date();
  
  return lastDate.toDateString() !== today.toDateString();
};

// Se for novo dia, resetar
if (profile && shouldResetDaily(profile.last_review_date)) {
  await supabase
    .from("profiles")
    .update({ daily_reviews_completed: 0 })
    .eq("user_id", session.user.id);
}
```

---

### **Opção 2: Trigger no Database** 🔧
**Vantagens:**
- Totalmente automático
- Centralizado no banco
- Mais robusto

**Implementação:**
Criar trigger que executa a cada query:

```sql
CREATE OR REPLACE FUNCTION check_and_reset_daily_reviews()
RETURNS TRIGGER AS $$
BEGIN
  -- Se last_review_date for diferente de hoje, reseta contador
  IF NEW.last_review_date IS NOT NULL AND NEW.last_review_date < CURRENT_DATE THEN
    NEW.daily_reviews_completed = 0;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reset_daily_reviews_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_and_reset_daily_reviews();
```

---

### **Opção 3: Modificar função increment_reviews()** 🎯
**Vantagens:**
- Lógica concentrada em um lugar
- Aproveita função existente

**Implementação:**
```sql
CREATE OR REPLACE FUNCTION public.increment_reviews(user_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_last_review_date DATE;
BEGIN
  -- Buscar última data de review
  SELECT last_review_date INTO current_last_review_date
  FROM public.profiles
  WHERE user_id = user_id_param;

  UPDATE public.profiles
  SET 
    -- Se for novo dia, começa do 1. Se não, incrementa
    daily_reviews_completed = CASE 
      WHEN current_last_review_date < CURRENT_DATE OR current_last_review_date IS NULL 
      THEN 1 
      ELSE daily_reviews_completed + 1 
    END,
    total_reviews = total_reviews + 1,
    balance = balance + 5.00,
    last_review_date = CURRENT_DATE,
    current_streak = CASE
      WHEN current_last_review_date = CURRENT_DATE - INTERVAL '1 day' THEN current_streak + 1
      WHEN current_last_review_date = CURRENT_DATE THEN current_streak
      ELSE 1
    END
  WHERE user_id = user_id_param;
END;
$$;
```

---

### **Opção 4: CRON Job no Supabase** ⏰
**Vantagens:**
- Reset exatamente à meia-noite
- Totalmente automático

**Implementação:**
```sql
-- Função para resetar todos os usuários
CREATE OR REPLACE FUNCTION reset_all_daily_reviews()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET daily_reviews_completed = 0
  WHERE last_review_date < CURRENT_DATE;
END;
$$;

-- Configurar no pg_cron (requer extensão)
SELECT cron.schedule(
  'reset-daily-reviews',
  '0 0 * * *',  -- Todo dia à meia-noite
  'SELECT reset_all_daily_reviews();'
);
```

---

## 🎯 RECOMENDAÇÃO FINAL

### **Solução Híbrida (Opção 1 + Opção 3):**

1. **Modificar `increment_reviews()`** para resetar automaticamente quando detectar novo dia
2. **Adicionar verificação no frontend** como backup/segurança extra
3. **Resultado**: Sistema robusto com múltiplas camadas de proteção

---

## 📝 RESUMO EXECUTIVO

| Aspecto | Status | Observação |
|---------|--------|------------|
| Campo no DB | ✅ Existe | `daily_reviews_completed` |
| Incremento | ✅ Funciona | Via `increment_reviews()` |
| Verificação | ✅ Funciona | Bloqueia em 5 avaliações |
| Reset Diário | ❌ **NÃO EXISTE** | **PROBLEMA CRÍTICO** |
| Impacto | 🔴 **ALTO** | Sistema trava após 1º dia |

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Análise concluída - Problema identificado
2. ⏳ **Aguardando decisão**: Qual solução implementar?
3. ⏳ Implementação da solução escolhida
4. ⏳ Testes de validação
5. ⏳ Deploy para produção

---

**Data da análise**: 14 de outubro de 2025  
**Analisado por**: GitHub Copilot  
**Criticidade**: 🔴 ALTA - Sistema não funcional após primeiro uso
