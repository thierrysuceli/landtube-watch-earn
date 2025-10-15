# 🧪 SQL Queries de Teste - Sistema de Lista Persistente

## 🎯 Como Usar

Copie e cole estas queries no **SQL Editor** do Supabase Dashboard para testar o sistema.

⚠️ **IMPORTANTE:** Substitua `'SEU_USER_ID_AQUI'` por um UUID real de usuário do seu banco!

---

## 📊 Queries de Verificação

### ✅ **1. Verificar se Tabela Existe**

```sql
SELECT 
  table_name, 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'daily_video_lists'
ORDER BY ordinal_position;
```

**Resultado Esperado:** 9 colunas listadas

---

### ✅ **2. Verificar Funções Criadas**

```sql
SELECT 
  p.proname AS function_name,
  pg_catalog.pg_get_function_arguments(p.oid) AS arguments,
  pg_catalog.pg_get_function_result(p.oid) AS return_type,
  p.prosecdef AS is_security_definer
FROM pg_catalog.pg_proc p
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('get_or_create_daily_list', 'update_list_progress')
ORDER BY p.proname;
```

**Resultado Esperado:** 2 funções com `is_security_definer = true`

---

### ✅ **3. Verificar RLS Policies**

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'daily_video_lists'
ORDER BY policyname;
```

**Resultado Esperado:** 3 policies (SELECT, INSERT, UPDATE)

---

### ✅ **4. Verificar Index**

```sql
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'daily_video_lists';
```

**Resultado Esperado:** Index em `(user_id, list_date)`

---

## 🎮 Queries de Teste Funcional

### ✅ **5. Pegar um User ID Real**

```sql
-- Listar primeiros 5 usuários
SELECT 
  id AS user_id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
```

**📝 Copie um `user_id` para usar nos próximos testes!**

---

### ✅ **6. Gerar Lista para User**

```sql
-- Substitua SEU_USER_ID_AQUI pelo UUID copiado acima
SELECT * FROM get_or_create_daily_list('SEU_USER_ID_AQUI');
```

**Resultado Esperado:**
```
list_id          | <uuid>
video_ids        | {uuid1,uuid2,uuid3,uuid4,uuid5}
current_video_index | 0
videos_completed | 0
is_completed     | false
list_date        | 2025-10-14
```

---

### ✅ **7. Ver Lista Criada**

```sql
SELECT 
  id,
  user_id,
  video_ids,
  array_length(video_ids, 1) AS total_videos_in_list,
  current_video_index,
  videos_completed,
  is_completed,
  list_date,
  created_at,
  updated_at
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
ORDER BY created_at DESC;
```

---

### ✅ **8. Ver Detalhes dos Vídeos da Lista**

```sql
-- Mostra informações dos vídeos que estão na lista
SELECT 
  v.id,
  v.title,
  v.earning_amount,
  v.duration,
  v.is_active
FROM daily_video_lists d
CROSS JOIN LATERAL unnest(d.video_ids) AS video_id
JOIN videos v ON v.id = video_id
WHERE d.user_id = 'SEU_USER_ID_AQUI'
  AND d.list_date = CURRENT_DATE;
```

---

### ✅ **9. Simular Assistir Primeiro Vídeo**

```sql
-- 1. Pegar ID do primeiro vídeo
SELECT video_ids[1] AS first_video_id
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND list_date = CURRENT_DATE;

-- 2. Inserir review manualmente
INSERT INTO reviews (user_id, video_id, rating, earning_amount)
VALUES (
  'SEU_USER_ID_AQUI',
  '<COLE_O_first_video_id_AQUI>',
  5,
  5.00
);

-- 3. Atualizar progresso da lista
SELECT update_list_progress('SEU_USER_ID_AQUI', 0);

-- 4. Verificar atualização
SELECT 
  videos_completed,
  current_video_index,
  is_completed
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND list_date = CURRENT_DATE;
```

**Resultado Esperado:**
```
videos_completed    | 1
current_video_index | 1
is_completed        | false
```

---

### ✅ **10. Completar Todos os Vídeos de Uma Vez**

```sql
-- Inserir reviews para todos os 5 vídeos
DO $$
DECLARE
  video_id_var UUID;
  video_ids_array UUID[];
  i INTEGER;
BEGIN
  -- Pegar array de video_ids
  SELECT video_ids INTO video_ids_array
  FROM daily_video_lists
  WHERE user_id = 'SEU_USER_ID_AQUI'
    AND list_date = CURRENT_DATE;
  
  -- Loop pelos vídeos
  FOR i IN 1..5 LOOP
    video_id_var := video_ids_array[i];
    
    -- Inserir review (se não existir)
    INSERT INTO reviews (user_id, video_id, rating, earning_amount)
    VALUES ('SEU_USER_ID_AQUI', video_id_var, 5, 5.00)
    ON CONFLICT (user_id, video_id) DO NOTHING;
    
    -- Atualizar progresso
    PERFORM update_list_progress('SEU_USER_ID_AQUI', i - 1);
  END LOOP;
END $$;

-- Verificar resultado
SELECT 
  videos_completed,
  is_completed
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND list_date = CURRENT_DATE;
```

**Resultado Esperado:**
```
videos_completed | 5
is_completed     | true
```

---

### ✅ **11. Verificar se Contador Diário Incrementou**

```sql
SELECT 
  daily_reviews_completed,
  total_reviews,
  balance,
  last_review_date
FROM profiles
WHERE user_id = 'SEU_USER_ID_AQUI';
```

**Resultado Esperado:**
```
daily_reviews_completed | 1 (ou mais)
balance                 | aumentou +$25
```

---

### ✅ **12. Tentar Gerar Lista Novamente (Deve Falhar)**

```sql
-- Tentar gerar segunda lista no mesmo dia
SELECT * FROM get_or_create_daily_list('SEU_USER_ID_AQUI');
```

**Resultado Esperado:** Retorna lista já completa (is_completed = true)

---

## 🧹 Queries de Limpeza

### ✅ **13. Resetar Lista de um User**

```sql
-- ⚠️ USE APENAS PARA TESTES!
DELETE FROM reviews 
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND completed_at::date = CURRENT_DATE;

DELETE FROM daily_video_lists 
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND list_date = CURRENT_DATE;

-- Resetar contador diário
UPDATE profiles
SET daily_reviews_completed = 0
WHERE user_id = 'SEU_USER_ID_AQUI';
```

---

### ✅ **14. Simular Novo Dia (Reset Diário)**

```sql
-- Mover lista para "ontem"
UPDATE daily_video_lists
SET list_date = CURRENT_DATE - INTERVAL '1 day'
WHERE user_id = 'SEU_USER_ID_AQUI'
  AND list_date = CURRENT_DATE;

-- Tentar gerar nova lista
SELECT * FROM get_or_create_daily_list('SEU_USER_ID_AQUI');
```

**Resultado Esperado:** Nova lista com vídeos diferentes

---

## 📊 Queries de Monitoramento

### ✅ **15. Dashboard - Estatísticas Gerais**

```sql
-- Resumo do dia
SELECT 
  COUNT(*) AS total_lists_today,
  COUNT(*) FILTER (WHERE is_completed = true) AS completed_lists,
  COUNT(*) FILTER (WHERE is_completed = false) AS incomplete_lists,
  ROUND(
    COUNT(*) FILTER (WHERE is_completed = true)::numeric / 
    NULLIF(COUNT(*)::numeric, 0) * 100, 
    2
  ) AS completion_rate_percent
FROM daily_video_lists
WHERE list_date = CURRENT_DATE;
```

---

### ✅ **16. Usuários Ativos Hoje**

```sql
SELECT 
  u.email,
  d.videos_completed,
  d.is_completed,
  d.created_at AS started_at,
  d.updated_at AS last_activity
FROM daily_video_lists d
JOIN auth.users u ON u.id = d.user_id
WHERE d.list_date = CURRENT_DATE
ORDER BY d.updated_at DESC;
```

---

### ✅ **17. Total Pago Hoje**

```sql
SELECT 
  SUM(v.earning_amount) AS total_earnings_today,
  COUNT(DISTINCT d.user_id) AS users_completed,
  AVG(v.earning_amount) AS avg_per_video
FROM daily_video_lists d
CROSS JOIN LATERAL unnest(d.video_ids) AS video_id
JOIN videos v ON v.id = video_id
WHERE d.list_date = CURRENT_DATE 
  AND d.is_completed = true;
```

---

### ✅ **18. Vídeos Mais Sorteados Hoje**

```sql
SELECT 
  v.id,
  v.title,
  COUNT(*) AS times_in_lists
FROM daily_video_lists d
CROSS JOIN LATERAL unnest(d.video_ids) AS video_id
JOIN videos v ON v.id = video_id
WHERE d.list_date = CURRENT_DATE
GROUP BY v.id, v.title
ORDER BY times_in_lists DESC
LIMIT 10;
```

---

### ✅ **19. Taxa de Abandono por Posição**

```sql
-- Quantos users pararam em cada vídeo
SELECT 
  current_video_index AS stopped_at_video,
  COUNT(*) AS users_count
FROM daily_video_lists
WHERE list_date = CURRENT_DATE
  AND is_completed = false
GROUP BY current_video_index
ORDER BY current_video_index;
```

---

### ✅ **20. Histórico de um User**

```sql
SELECT 
  list_date,
  videos_completed,
  is_completed,
  created_at,
  updated_at,
  updated_at - created_at AS time_to_complete
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
ORDER BY list_date DESC
LIMIT 30;
```

---

## 🐛 Queries de Debug

### ✅ **21. Verificar Vídeos Disponíveis para User**

```sql
-- Vídeos que este user ainda não assistiu
SELECT 
  v.id,
  v.title,
  v.earning_amount,
  v.is_active
FROM videos v
WHERE v.is_active = true
  AND v.id NOT IN (
    SELECT video_id 
    FROM reviews 
    WHERE user_id = 'SEU_USER_ID_AQUI'
  )
ORDER BY v.created_at DESC;
```

---

### ✅ **22. Verificar Permissões de Funções**

```sql
SELECT 
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name IN ('get_or_create_daily_list', 'update_list_progress')
ORDER BY routine_name, grantee;
```

**Resultado Esperado:** `authenticated` role com `EXECUTE` permission

---

### ✅ **23. Ver Logs de Erro (se houver)**

```sql
-- No Supabase Dashboard:
-- Logs → Postgres Logs → Filter: ERROR
```

---

## ✅ Checklist de Testes

Use este checklist após aplicar a migration:

- [ ] Query 1: Tabela criada (9 colunas)
- [ ] Query 2: Funções criadas (2)
- [ ] Query 3: RLS policies (3)
- [ ] Query 4: Index criado
- [ ] Query 6: Lista gerada com sucesso
- [ ] Query 7: Lista visível no banco
- [ ] Query 8: Vídeos detalhados carregam
- [ ] Query 9: Progresso atualiza corretamente
- [ ] Query 10: Completar lista funciona
- [ ] Query 11: Contador incrementa
- [ ] Query 12: Segunda lista bloqueada
- [ ] Query 14: Reset diário funciona

---

## 🎉 Pronto!

Se todos os testes passaram, o sistema está funcionando perfeitamente!

**Próximo passo:** Testar no frontend navegando para `/review`
