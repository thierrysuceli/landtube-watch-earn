# 🚀 Guia de Deploy - Sistema de Lista Persistente

## 📋 Pré-requisitos

- Acesso ao Dashboard do Supabase
- Projeto LandTube conectado

---

## 🗄️ Passo 1: Aplicar Migration no Banco

### **Opção A: Via Supabase Dashboard (Recomendado)**

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto **LandTube**
3. No menu lateral, clique em **SQL Editor**
4. Clique em **New Query**
5. Copie TODO o conteúdo do arquivo:
   ```
   supabase/migrations/20251014200000_create_daily_video_lists.sql
   ```
6. Cole no editor SQL
7. Clique em **RUN** (ou pressione Ctrl+Enter)
8. ✅ Aguarde mensagem de sucesso

### **Opção B: Via Supabase CLI**

Se você tiver o CLI instalado:

```bash
cd C:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main
supabase db push
```

---

## ✅ Passo 2: Verificar Criação

No SQL Editor do Supabase, execute:

```sql
-- 1. Verificar se tabela foi criada
SELECT 
  table_name, 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_video_lists'
ORDER BY ordinal_position;

-- 2. Verificar se funções foram criadas
SELECT 
  proname AS function_name,
  pg_get_function_result(oid) AS return_type
FROM pg_proc 
WHERE proname IN ('get_or_create_daily_list', 'update_list_progress');

-- 3. Verificar RLS policies
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename = 'daily_video_lists';
```

**Resultado Esperado:**
- ✅ Tabela `daily_video_lists` com 9 colunas
- ✅ 2 funções criadas
- ✅ 3 policies de RLS

---

## 🧪 Passo 3: Testar Funções

### **Teste 1: Gerar Lista para um Usuário**

```sql
-- Substitua 'SEU_USER_ID_AQUI' pelo UUID de um usuário real
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

### **Teste 2: Verificar Lista Criada**

```sql
-- Ver todas as listas criadas hoje
SELECT 
  id,
  user_id,
  array_length(video_ids, 1) as total_videos,
  videos_completed,
  is_completed,
  list_date,
  created_at
FROM daily_video_lists
WHERE list_date = CURRENT_DATE
ORDER BY created_at DESC;
```

### **Teste 3: Simular Progresso**

```sql
-- Atualizar progresso manualmente
SELECT update_list_progress('SEU_USER_ID_AQUI', 0);

-- Verificar atualização
SELECT videos_completed, current_video_index, is_completed
FROM daily_video_lists
WHERE user_id = 'SEU_USER_ID_AQUI'
AND list_date = CURRENT_DATE;
```

---

## 🔍 Passo 4: Validar Integridade

### **Check 1: Constraint UNIQUE**
```sql
-- Tentar criar lista duplicada (deve falhar)
INSERT INTO daily_video_lists (user_id, list_date, video_ids)
VALUES (
  'SEU_USER_ID_AQUI',
  CURRENT_DATE,
  ARRAY['uuid1','uuid2','uuid3','uuid4','uuid5']::uuid[]
);
-- ❌ Deve retornar erro: duplicate key value violates unique constraint
```

### **Check 2: RLS Funcionando**
```sql
-- Verificar se policies estão ativas
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'daily_video_lists';
-- ✅ rowsecurity deve ser TRUE
```

### **Check 3: Trigger Updated_At**
```sql
-- Atualizar registro e verificar updated_at
UPDATE daily_video_lists 
SET videos_completed = 1 
WHERE user_id = 'SEU_USER_ID_AQUI' 
AND list_date = CURRENT_DATE;

-- Verificar updated_at mudou
SELECT updated_at FROM daily_video_lists 
WHERE user_id = 'SEU_USER_ID_AQUI' 
AND list_date = CURRENT_DATE;
-- ✅ updated_at deve ser timestamp recente
```

---

## 🎨 Passo 5: Build e Deploy Frontend

### **Verificar Tipos TypeScript**

Arquivo já atualizado: `src/integrations/supabase/types.ts`

✅ Tabela `daily_video_lists` adicionada  
✅ Funções `get_or_create_daily_list` e `update_list_progress` tipadas

### **Build Local**

```bash
cd C:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main
npm install
npm run build
```

**Verificar:**
- ✅ Sem erros de compilação
- ✅ Build gerado em `dist/`

### **Deploy (conforme seu setup)**

**Vercel:**
```bash
vercel --prod
```

**Netlify:**
```bash
netlify deploy --prod
```

**Ou:** Faça commit e push para GitHub (se tiver CI/CD configurado)

---

## 📊 Passo 6: Teste de Integração

### **Cenário 1: Primeira Visita**

1. Abra o site
2. Faça login
3. Clique em **Review Videos** (ou acesse `/review`)
4. ✅ Deve carregar 5 vídeos novos
5. ✅ Deve mostrar "Video 1 of 5"
6. ✅ Indicadores: 🟢⚪⚪⚪⚪

### **Cenário 2: Progresso Persistente**

1. Assista vídeo 1, avalie com 5 estrelas
2. Clique "Rate & Next"
3. ✅ Deve mostrar toast: "Review saved! Moving to next video..."
4. ✅ Deve carregar vídeo 2
5. **Feche o navegador**
6. Abra novamente e acesse `/review`
7. ✅ Deve mostrar toast: "Continue reviewing! 1/5 videos completed"
8. ✅ Deve estar no vídeo 2
9. ✅ Indicadores: 🟢🔵⚪⚪⚪ (verde = completo, azul = atual)

### **Cenário 3: Exploit Bloqueado**

1. Complete todos os 5 vídeos
2. ✅ Deve mostrar CompletionModal
3. ✅ Balance deve aumentar +$25
4. Clique "Continue" → vai para Dashboard
5. **Tente acessar `/review` novamente**
6. ✅ Deve redirecionar para Dashboard
7. ✅ Toast: "You've already completed your daily reviews!"

### **Cenário 4: Multi-aba**

1. Abra `/review` em 2 abas
2. Na Aba 1: assista vídeo 1
3. Na Aba 2: **recarregue a página**
4. ✅ Aba 2 deve mostrar "1/5 completed"
5. ✅ Aba 2 deve estar no vídeo 2

---

## 🐛 Troubleshooting

### **Erro: "Not enough available videos"**

**Causa:** Usuário já assistiu todos os vídeos do banco

**Solução:**
```sql
-- Adicionar mais vídeos
INSERT INTO videos (title, thumbnail_url, earning_amount, is_active) VALUES
  ('New Video 1', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 5.00, true),
  ('New Video 2', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 5.00, true),
  ('New Video 3', 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg', 5.00, true);
```

### **Erro: "Failed to load daily list"**

**Debug:**
```sql
-- Verificar se função existe e tem permissões
SELECT 
  p.proname,
  pg_catalog.pg_get_function_arguments(p.oid) as arguments,
  pg_catalog.pg_get_function_result(p.oid) as result_type
FROM pg_catalog.pg_proc p
WHERE p.proname = 'get_or_create_daily_list';
```

**Fix:**
```sql
-- Re-aplicar permissões
GRANT EXECUTE ON FUNCTION get_or_create_daily_list(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_list_progress(UUID, INTEGER) TO authenticated;
```

### **Lista não sincroniza entre abas**

**Verificar:**
1. Abra DevTools → Network tab
2. Recarregue a página
3. ✅ Deve ter chamada `POST /rest/v1/rpc/get_or_create_daily_list`

**Se não aparecer:**
```typescript
// Adicionar log no Review.tsx
console.log('Calling get_or_create_daily_list...', userId);
const { data, error } = await supabase.rpc("get_or_create_daily_list", {
  user_id_param: userId,
});
console.log('Result:', { data, error });
```

### **Pagamento não credita**

**Debug:**
```sql
-- Verificar se lista foi marcada como completa
SELECT * FROM daily_video_lists 
WHERE user_id = 'SEU_USER_ID' 
AND list_date = CURRENT_DATE;
-- is_completed deve ser TRUE

-- Verificar reviews salvos
SELECT COUNT(*) as total_reviews
FROM reviews 
WHERE user_id = 'SEU_USER_ID'
AND completed_at::date = CURRENT_DATE;
-- Deve retornar 5

-- Verificar balance
SELECT balance FROM profiles WHERE user_id = 'SEU_USER_ID';
```

---

## 📊 Monitoramento (Queries Úteis)

### **Dashboard Admin - Estatísticas do Dia**

```sql
-- Listas criadas hoje
SELECT COUNT(*) as total_lists_today
FROM daily_video_lists
WHERE list_date = CURRENT_DATE;

-- Listas completadas hoje
SELECT COUNT(*) as completed_lists_today
FROM daily_video_lists
WHERE list_date = CURRENT_DATE AND is_completed = true;

-- Taxa de conclusão
SELECT 
  ROUND(
    COUNT(CASE WHEN is_completed THEN 1 END)::numeric / 
    NULLIF(COUNT(*)::numeric, 0) * 100, 
    2
  ) as completion_rate_percent
FROM daily_video_lists
WHERE list_date = CURRENT_DATE;

-- Usuários que abandonaram (não completaram)
SELECT 
  u.email,
  d.videos_completed,
  d.created_at,
  d.updated_at
FROM daily_video_lists d
JOIN auth.users u ON u.id = d.user_id
WHERE d.list_date = CURRENT_DATE 
  AND d.is_completed = false
ORDER BY d.updated_at DESC;

-- Total pago hoje
SELECT 
  SUM(v.earning_amount) as total_paid_today
FROM daily_video_lists d
CROSS JOIN LATERAL unnest(d.video_ids) AS video_id
JOIN videos v ON v.id = video_id
WHERE d.list_date = CURRENT_DATE AND d.is_completed = true;
```

---

## ✅ Checklist Final de Deploy

### **Backend:**
- [ ] Migration aplicada no Supabase
- [ ] Tabela `daily_video_lists` criada
- [ ] Funções SQL criadas e testadas
- [ ] RLS policies ativas
- [ ] Indexes criados
- [ ] Triggers funcionando

### **Frontend:**
- [ ] Types atualizados
- [ ] Review.tsx sem erros de compilação
- [ ] Build gerado sem warnings
- [ ] Deploy realizado

### **Testes:**
- [ ] Primeira visita funciona
- [ ] Progresso persiste após reload
- [ ] Exploit bloqueado (não pode fazer mais de 1 lista/dia)
- [ ] Multi-aba sincroniza
- [ ] Pagamento credita corretamente
- [ ] Reset diário funciona

### **Documentação:**
- [ ] SISTEMA_LISTA_PERSISTENTE.md criado
- [ ] GUIA_DEPLOY.md criado
- [ ] README.md atualizado (se necessário)

---

## 🎉 Sucesso!

Se todos os testes passaram, o sistema está pronto para produção!

**Resultado Final:**
- ✅ Exploit de reload eliminado
- ✅ Progresso persistente e confiável
- ✅ UX melhorada significativamente
- ✅ Pagamento justo e transparente
- ✅ Sistema escalável e seguro

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique logs do Supabase: Dashboard → Logs
2. Verifique console do navegador: DevTools → Console
3. Revise a documentação: `SISTEMA_LISTA_PERSISTENTE.md`
4. Execute queries de debug listadas acima

**Boa sorte! 🚀**
