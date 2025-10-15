# 🚀 Deploy Rápido - LandTube no GitHub Pages

## ⚡ VOCÊ JÁ TEM O REPO - VAMOS DIRETO!

Repositório: **landtube-watch-earn** ✅

---

## 📝 COMANDOS - COPIE E EXECUTE

### 1. Configure o Git (se nunca configurou)

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

### 2. Entre na pasta do projeto

```powershell
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main
```

### 3. Inicialize o repositório Git

```powershell
git init
git add .
git commit -m "Deploy LandTube - Watch and Earn Platform"
git branch -M main
```

### 4. Conecte ao seu repositório

**⚠️ IMPORTANTE: Substitua `SEU-USUARIO` pelo seu usuário do GitHub!**

```powershell
git remote add origin https://github.com/SEU-USUARIO/landtube-watch-earn.git
git push -u origin main
```

**Exemplo:**
```powershell
# Se seu usuário é "joaosilva"
git remote add origin https://github.com/joaosilva/landtube-watch-earn.git
git push -u origin main
```

---

## 🎯 DEPOIS DO PUSH

### 5. Ativar GitHub Pages (só fazer uma vez)

1. Acesse: `https://github.com/SEU-USUARIO/landtube-watch-earn`
2. Clique em **Settings** (⚙️ Configurações)
3. Menu lateral → **Pages**
4. Em **Source**, selecione: **GitHub Actions**
5. Pronto! ✅

### 6. Aguardar Deploy

- Vá em **Actions** no repositório
- Aguarde o workflow "Deploy to GitHub Pages" terminar (✅ verde)
- Leva ~2-3 minutos

### 7. Acessar Seu Site

```
https://SEU-USUARIO.github.io/landtube-watch-earn/
```

**Exemplo:**
```
https://joaosilva.github.io/landtube-watch-earn/
```

---

## 🔄 ATUALIZAÇÕES FUTURAS

Quando fizer mudanças:

```powershell
git add .
git commit -m "Descrição da mudança"
git push
```

Deploy automático em 2 minutos! 🚀

---

## 🆘 PROBLEMAS COMUNS

### ❌ "remote origin already exists"

```powershell
git remote remove origin
git remote add origin https://github.com/SEU-USUARIO/landtube-watch-earn.git
git push -u origin main
```

### ❌ "failed to push some refs"

```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main --force
```

### ❌ Pede senha no push

Use um **Personal Access Token**:
1. Acesse: https://github.com/settings/tokens
2. Clique em **Generate new token** → **Classic**
3. Marque: `repo` (todas as opções)
4. Clique em **Generate token**
5. Copie o token (parecido com: `ghp_xxxxxxxxxxxx`)
6. Use o token como senha quando pedir

---

## ✅ CHECKLIST

- [ ] Configurei nome e email no Git
- [ ] Estou na pasta do projeto
- [ ] Executei os comandos de inicialização
- [ ] Conectei ao repositório (substitui SEU-USUARIO)
- [ ] Fiz o push com sucesso
- [ ] Ativei GitHub Pages (Settings → Pages → GitHub Actions)
- [ ] Aguardei o deploy terminar (Actions)
- [ ] Testei a URL final

---

## 🎉 RESUMO - 4 COMANDOS ESSENCIAIS

```powershell
# 1. Ir para pasta
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main

# 2. Inicializar Git
git init && git add . && git commit -m "Deploy LandTube" && git branch -M main

# 3. Conectar ao repo (SUBSTITUA SEU-USUARIO!)
git remote add origin https://github.com/SEU-USUARIO/landtube-watch-earn.git

# 4. Enviar código
git push -u origin main
```

**Depois: Settings → Pages → GitHub Actions**

**Pronto! Site no ar em 3 minutos! 🚀**

---

## 📞 SUA URL FINAL

Anote aqui:
```
https://________________.github.io/landtube-watch-earn/
```

**Teste tudo:**
- [ ] Página carrega
- [ ] Login funciona
- [ ] Vídeos aparecem
- [ ] Ganha pontos ao completar

---

**Qualquer erro, me avise! 😊**
