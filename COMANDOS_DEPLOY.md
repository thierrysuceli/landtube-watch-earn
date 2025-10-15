# 🚀 Deploy Rápido - Comandos Prontos

## ⚡ COMANDOS COPY & PASTE

### 1. Configure o Git (apenas primeira vez)
```powershell
git config --global user.name "Seu Nome Aqui"
git config --global user.email "seuemail@exemplo.com"
```

### 2. Entre na pasta do projeto
```powershell
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main
```

### 3. Inicialize e faça primeiro commit
```powershell
git init
git add .
git commit -m "Initial commit - LandTube Watch & Earn"
git branch -M main
```

### 4. Conecte ao GitHub
**⚠️ IMPORTANTE: Substitua `SEU-USUARIO` e `NOME-DO-REPO` antes de executar!**

```powershell
git remote add origin https://github.com/SEU-USUARIO/NOME-DO-REPO.git
git push -u origin main
```

**Exemplo real:**
```powershell
git remote add origin https://github.com/joaosilva/landtube-watch-earn.git
git push -u origin main
```

---

## 📝 ANTES DE EXECUTAR

### ✅ Checklist Pré-Deploy

1. [ ] **Criar repositório no GitHub**
   - Acesse: https://github.com/new
   - Nome: `landtube-watch-earn` (ou outro)
   - Visibility: ✅ Public
   - ❌ NÃO inicializar com README

2. [ ] **Anotar nome exato do repositório**
   - O nome que você escolheu: `________________`

3. [ ] **Atualizar `vite.config.ts`**
   - Abra: `vite.config.ts`
   - Linha 8: Mude `landtube-watch-earn` para o nome do seu repo
   ```typescript
   base: mode === "production" ? "/SEU-REPO-AQUI/" : "/",
   ```

4. [ ] **Verificar que `.env` não será enviado**
   - Arquivo `.gitignore` já inclui `.env`
   - ✅ Verificado automaticamente

---

## 🎯 DEPOIS DO PUSH

### 5. Ativar GitHub Pages

1. Acesse seu repositório: `https://github.com/SEU-USUARIO/NOME-DO-REPO`
2. Clique em **Settings** (⚙️)
3. No menu lateral → **Pages**
4. Em **Source** selecione: **GitHub Actions**
5. Pronto! GitHub Pages está ativo ✅

### 6. Disparar Deploy

**Opção A - Automático:**
- O deploy já está rodando (verifique em **Actions**)

**Opção B - Manual:**
1. Vá em **Actions**
2. Clique em **Deploy to GitHub Pages**
3. Botão **Run workflow** → **Run workflow**

### 7. Aguardar Deploy (2-3 minutos)

Acompanhe em **Actions**. Quando aparecer ✅ verde, está pronto!

### 8. Acessar Seu Site

```
https://SEU-USUARIO.github.io/NOME-DO-REPO/
```

**Exemplo:**
```
https://joaosilva.github.io/landtube-watch-earn/
```

---

## 🔄 ATUALIZAÇÕES FUTURAS

Quando fizer mudanças no projeto:

```powershell
git add .
git commit -m "Descrição da mudança"
git push
```

Deploy acontece automaticamente em ~2 minutos.

---

## 🆘 PROBLEMAS COMUNS

### ❌ "fatal: remote origin already exists"
```powershell
git remote remove origin
git remote add origin https://github.com/SEU-USUARIO/NOME-DO-REPO.git
```

### ❌ "error: failed to push some refs"
```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### ❌ Página em branco após deploy
1. Verifique `vite.config.ts` linha 8
2. O `base` deve ter o nome EXATO do repo
3. Refaça o build: `git commit --allow-empty -m "Rebuild" && git push`

### ❌ "Failed to fetch" ao fazer login
- Variáveis de ambiente do `.env` estão no código após build
- Se o problema persistir, adicione como GitHub Secrets:
  1. Settings → Secrets and variables → Actions
  2. New repository secret
  3. Adicione `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`

---

## 📋 RESUMO - 4 PASSOS

```powershell
# 1. Ir para pasta do projeto
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main

# 2. Inicializar Git
git init && git add . && git commit -m "Initial commit" && git branch -M main

# 3. Conectar ao GitHub (SUBSTITUA!)
git remote add origin https://github.com/SEU-USUARIO/NOME-DO-REPO.git
git push -u origin main

# 4. Ativar GitHub Pages no repositório (Settings → Pages → GitHub Actions)
```

**Pronto! Seu site estará online em 3 minutos! 🎉**

---

## 📞 URL FINAL

Anote aqui sua URL:
```
https://________________.github.io/________________/
```

**Teste:**
- [ ] Página abre
- [ ] Login funciona
- [ ] Vídeos carregam
- [ ] Ganha pontos ao completar

---

**Siga os comandos na ordem e estará no ar! 🚀**
