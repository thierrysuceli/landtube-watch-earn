# 🚀 Guia de Deploy - GitHub Pages

## 📋 PRÉ-REQUISITOS

- [ ] Conta no GitHub
- [ ] Git instalado no computador
- [ ] Projeto já funcionando localmente

---

## 🎯 PASSO A PASSO COMPLETO

### 1️⃣ Criar Repositório no GitHub

1. Acesse https://github.com/new
2. Preencha:
   - **Repository name**: `landtube-watch-earn` (ou outro nome)
   - **Description**: "LandTube - Watch and Earn Platform"
   - **Visibility**: ✅ Public (para GitHub Pages grátis)
   - ❌ NÃO marque "Initialize with README"
3. Clique em **Create repository**
4. **IMPORTANTE**: Copie o nome exato do repositório que você escolheu

---

### 2️⃣ Atualizar Configuração do Vite

Abra o arquivo `vite.config.ts` e **substitua** `landtube-watch-earn` pelo nome EXATO do seu repositório:

```typescript
// Se seu repo se chamar "meu-projeto", mude para:
base: mode === "production" ? "/meu-projeto/" : "/",
```

**⚠️ ATENÇÃO**: O nome deve ser EXATAMENTE o mesmo do repositório GitHub!

---

### 3️⃣ Inicializar Git e Fazer Primeiro Commit

Abra o PowerShell na pasta do projeto e execute:

```powershell
# Navegue até a pasta do projeto
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main

# Inicializa git (se ainda não foi inicializado)
git init

# Adiciona todos os arquivos
git add .

# Faz o primeiro commit
git commit -m "Initial commit - LandTube Watch & Earn"

# Renomeia branch para main (GitHub Pages usa 'main')
git branch -M main
```

---

### 4️⃣ Conectar ao Repositório GitHub

**IMPORTANTE**: Substitua `SEU-USUARIO` e `NOME-DO-REPO` pelos seus dados reais:

```powershell
# Adiciona repositório remoto
git remote add origin https://github.com/SEU-USUARIO/NOME-DO-REPO.git

# Faz push do código
git push -u origin main
```

**Exemplo real**:
```powershell
git remote add origin https://github.com/joaosilva/landtube-watch-earn.git
git push -u origin main
```

---

### 5️⃣ Ativar GitHub Pages

1. Acesse seu repositório no GitHub
2. Vá em **Settings** (⚙️ Configurações)
3. No menu lateral, clique em **Pages**
4. Em **Source**, selecione:
   - **Source**: ✅ GitHub Actions
5. Aguarde alguns segundos
6. A página deve mostrar: "Your site is ready to be published"

---

### 6️⃣ Disparar Deploy Automático

O deploy acontece automaticamente quando você faz push, mas você pode forçar:

**Opção A - Via GitHub (mais fácil)**:
1. Vá em **Actions** no seu repositório
2. Clique em **Deploy to GitHub Pages**
3. Clique em **Run workflow** → **Run workflow**
4. Aguarde o deploy (leva ~2-3 minutos)

**Opção B - Via Git (fazendo uma mudança)**:
```powershell
# Faz uma pequena mudança (ex: edita README.md)
git add .
git commit -m "Trigger deploy"
git push
```

---

### 7️⃣ Verificar Deploy

1. Vá em **Actions** no GitHub
2. Você verá o workflow "Deploy to GitHub Pages" rodando
3. Aguarde aparecer ✅ (verde)
4. Seu site estará disponível em:
   ```
   https://SEU-USUARIO.github.io/NOME-DO-REPO/
   ```

**Exemplo**:
```
https://joaosilva.github.io/landtube-watch-earn/
```

---

## 🔧 CONFIGURAÇÕES IMPORTANTES

### ⚠️ Arquivo .env NO GITHUB

**NUNCA** suba o arquivo `.env` com credenciais reais! Ele já está no `.gitignore`, mas verifique:

```powershell
# Verifique se .env está no .gitignore
cat .gitignore | Select-String ".env"
```

Deve aparecer:
```
.env
.env.local
.env.production
```

### 🔒 Variáveis de Ambiente no GitHub Pages

Como o `.env` não vai para o GitHub, você tem 2 opções:

**Opção 1 - Variáveis públicas** (recomendado para Supabase anon key):

As variáveis do `.env` já estão no código quando você faz build. O `VITE_SUPABASE_ANON_KEY` é seguro de expor publicamente (é design do Supabase).

**Opção 2 - GitHub Secrets** (para segredo extra):

1. Vá em **Settings** → **Secrets and variables** → **Actions**
2. Clique em **New repository secret**
3. Adicione:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

Depois, edite `.github/workflows/deploy.yml` para usar:
```yaml
- name: Build
  run: npm run build
  env:
    VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
    VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}
```

---

## ✅ CHECKLIST FINAL

Antes de fazer deploy, verifique:

- [ ] `.env` NÃO está sendo commitado (está no `.gitignore`)
- [ ] `vite.config.ts` tem o `base` correto com nome do repositório
- [ ] Repositório GitHub foi criado
- [ ] Git foi inicializado e código foi enviado
- [ ] GitHub Pages foi ativado (Source: GitHub Actions)
- [ ] Workflow está rodando sem erros

---

## 🐛 PROBLEMAS COMUNS

### ❌ Página em branco no GitHub Pages

**Causa**: `base` incorreto no `vite.config.ts`

**Solução**:
```typescript
// Certifique-se que o nome do repo está correto:
base: mode === "production" ? "/SEU-REPO-EXATO/" : "/",
```

### ❌ CSS não carrega

**Causa**: Mesmo problema do `base`

**Solução**: Verifique se o `base` termina com `/`

### ❌ "Failed to fetch" ao fazer login

**Causa**: Variáveis de ambiente não foram incluídas no build

**Solução 1**: Certifique-se que `.env` existe e tem as variáveis corretas antes de fazer build local

**Solução 2**: Use GitHub Secrets (veja seção "Variáveis de Ambiente" acima)

### ❌ Deploy falha no GitHub Actions

**Causa**: Erro no `npm ci` ou `npm run build`

**Solução**:
1. Teste localmente: `npm run build`
2. Se funcionar local, problema é de variáveis de ambiente
3. Adicione secrets no GitHub (veja acima)

### ❌ 404 ao acessar rotas (ex: /dashboard)

**Causa**: GitHub Pages não suporta client-side routing do React Router

**Solução**: Adicione arquivo `404.html` que redireciona para `index.html`

Crie `public/404.html`:
```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <script>
      sessionStorage.redirect = location.href;
    </script>
    <meta http-equiv="refresh" content="0;URL='/landtube-watch-earn'">
  </head>
</html>
```

E adicione no `index.html` antes de `</head>`:
```html
<script>
  (function() {
    var redirect = sessionStorage.redirect;
    delete sessionStorage.redirect;
    if (redirect && redirect != location.href) {
      history.replaceState(null, null, redirect);
    }
  })();
</script>
```

---

## 🔄 ATUALIZAÇÕES FUTURAS

Quando fizer mudanças no projeto:

```powershell
# Adiciona mudanças
git add .

# Commit com mensagem descritiva
git commit -m "Adiciona nova funcionalidade X"

# Envia para GitHub (dispara deploy automático)
git push
```

O deploy acontece automaticamente em ~2-3 minutos.

---

## 📞 PRÓXIMOS PASSOS APÓS DEPLOY

1. ✅ Acesse sua URL do GitHub Pages
2. ✅ Teste login/cadastro
3. ✅ Teste assistir vídeos
4. ✅ Verifique se ganha pontos
5. ✅ Teste em dispositivos móveis

---

## 🎉 EXEMPLO COMPLETO DE COMANDOS

Aqui está a sequência completa do zero:

```powershell
# 1. Vá para pasta do projeto
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main

# 2. Configure git (primeira vez apenas)
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# 3. Inicialize repositório
git init
git add .
git commit -m "Initial commit - LandTube Watch & Earn"
git branch -M main

# 4. Conecte ao GitHub (SUBSTITUA COM SEUS DADOS!)
git remote add origin https://github.com/SEU-USUARIO/landtube-watch-earn.git
git push -u origin main

# 5. Vá no GitHub e ative GitHub Pages (Settings → Pages → Source: GitHub Actions)

# 6. Aguarde deploy automático ou force via Actions → Run workflow

# 7. Acesse: https://SEU-USUARIO.github.io/landtube-watch-earn/
```

---

**Siga este guia passo a passo e seu projeto estará no ar! 🚀**

**Alguma dúvida? Me avise qual passo está tendo dificuldade! 😊**
