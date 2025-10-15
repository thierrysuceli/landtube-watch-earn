# LandTube - Watch & Earn 🎬💰

Plataforma para ganhar dinheiro assistindo e avaliando vídeos do YouTube.

## 🚀 Deploy no GitHub Pages

### Método 1: Script Automático (Recomendado)

Execute o script de deploy automático:

```powershell
# 1. Abra o PowerShell na pasta do projeto
cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main

# 2. Execute o script de deploy
.\deploy.ps1
```

O script vai:
- ✅ Configurar Git
- ✅ Atualizar configurações do Vite
- ✅ Fazer commit e push
- ✅ Mostrar próximos passos

### Método 2: Manual

Siga o guia detalhado em: [COMANDOS_DEPLOY.md](./COMANDOS_DEPLOY.md)

## 📋 Pré-requisitos

1. Criar repositório no GitHub: https://github.com/new
2. Nome sugerido: `landtube-watch-earn`
3. Visibility: Public

## 🌐 URL Final

Após o deploy, seu site estará disponível em:
```
https://SEU-USUARIO.github.io/NOME-DO-REPO/
```

## 🔧 Tecnologias

- React 18
- TypeScript
- Vite
- Tailwind CSS
- Supabase (Backend)
- shadcn/ui (Componentes)

## 📱 Funcionalidades

- ✅ Sistema de autenticação
- ✅ Assistir vídeos do YouTube
- ✅ Sistema de avaliação (1-5 estrelas)
- ✅ Ganho de pontos por vídeo assistido
- ✅ Dashboard com estatísticas
- ✅ Sistema de listas diárias (5 vídeos)
- ✅ Bônus por completar lista
- ✅ Sistema de sequência de dias
- ✅ Reset automático diário

## 🔒 Segurança

- RLS (Row Level Security) ativo no Supabase
- Variáveis de ambiente protegidas
- Autenticação JWT via Supabase

## 📞 Suporte

- Guia completo: [DEPLOY_GITHUB_PAGES.md](./DEPLOY_GITHUB_PAGES.md)
- Comandos rápidos: [COMANDOS_DEPLOY.md](./COMANDOS_DEPLOY.md)

---

**Desenvolvido com ❤️ para transformar tempo em recompensas**
