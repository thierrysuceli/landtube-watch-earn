# 🚀 Script de Deploy Automático - LandTube
# Execute este script para fazer deploy no GitHub Pages

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  LANDTUBE - DEPLOY AUTOMÁTICO GITHUB PAGES" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está na pasta correta
if (!(Test-Path "vite.config.ts")) {
    Write-Host "❌ ERRO: Execute este script na pasta do projeto!" -ForegroundColor Red
    Write-Host "   cd c:\Users\silva\Downloads\landtube-watch-earn-main\landtube-watch-earn-main" -ForegroundColor Yellow
    exit 1
}

# Passo 1: Informações do usuário
Write-Host "📝 PASSO 1: Configuração" -ForegroundColor Green
Write-Host ""

$gitName = Read-Host "Digite seu nome (para Git)"
$gitEmail = Read-Host "Digite seu email (para Git)"
$githubUser = Read-Host "Digite seu usuário do GitHub"
$repoName = "landtube-watch-earn"

Write-Host ""
Write-Host "✅ Repositório configurado: landtube-watch-earn" -ForegroundColor Green

Write-Host ""
Write-Host "⚙️  Configurando Git..." -ForegroundColor Yellow

git config --global user.name "$gitName"
git config --global user.email "$gitEmail"

# Passo 2: Confirmação
Write-Host ""
Write-Host "📝 PASSO 2: Configuração confirmada" -ForegroundColor Green
Write-Host "   Nome: $gitName" -ForegroundColor White
Write-Host "   Email: $gitEmail" -ForegroundColor White
Write-Host "   GitHub User: $githubUser" -ForegroundColor White
Write-Host "   Repositório: landtube-watch-earn (já configurado)" -ForegroundColor White
Write-Host "   Base URL: /landtube-watch-earn/ (já configurado)" -ForegroundColor White
Write-Host ""

# Passo 3: Inicializar Git
Write-Host ""
Write-Host "📝 PASSO 3: Inicializando repositório Git" -ForegroundColor Green

# Verificar se já tem .git
if (Test-Path ".git") {
    Write-Host "⚠️  Repositório Git já existe. Deseja reinicializar? (S/N)" -ForegroundColor Yellow
    $reinit = Read-Host
    if ($reinit -eq "S" -or $reinit -eq "s") {
        Remove-Item -Recurse -Force ".git"
        git init
        Write-Host "✅ Git reinicializado" -ForegroundColor Green
    }
} else {
    git init
    Write-Host "✅ Git inicializado" -ForegroundColor Green
}

# Passo 4: Adicionar arquivos
Write-Host ""
Write-Host "📝 PASSO 4: Adicionando arquivos" -ForegroundColor Green

git add .
git commit -m "Initial commit - LandTube Watch & Earn"
git branch -M main

Write-Host "✅ Arquivos commitados" -ForegroundColor Green

# Passo 5: Conectar ao GitHub
Write-Host ""
Write-Host "📝 PASSO 5: Conectando ao GitHub" -ForegroundColor Green

# Remover remote se já existir
git remote remove origin 2>$null

$remoteUrl = "https://github.com/$githubUser/$repoName.git"
git remote add origin $remoteUrl

Write-Host "✅ Conectado ao repositório: $remoteUrl" -ForegroundColor Green

# Passo 6: Push para GitHub
Write-Host ""
Write-Host "📝 PASSO 6: Enviando código para GitHub" -ForegroundColor Green
Write-Host "⚠️  Se pedir senha, use um Personal Access Token!" -ForegroundColor Yellow
Write-Host ""

try {
    git push -u origin main
    Write-Host ""
    Write-Host "✅ Código enviado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "⚠️  Erro ao fazer push. Você criou o repositório no GitHub?" -ForegroundColor Yellow
    Write-Host "   1. Acesse: https://github.com/new" -ForegroundColor Cyan
    Write-Host "   2. Crie o repositório: $repoName" -ForegroundColor Cyan
    Write-Host "   3. Execute novamente: git push -u origin main" -ForegroundColor Yellow
    exit 1
}

# Passo 7: Instruções finais
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ✅ DEPLOY CONFIGURADO COM SUCESSO!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Acesse seu repositório:" -ForegroundColor White
Write-Host "   https://github.com/$githubUser/$repoName" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Vá em Settings → Pages" -ForegroundColor White
Write-Host ""
Write-Host "3. Em 'Source', selecione: GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "4. Aguarde 2-3 minutos e acesse:" -ForegroundColor White
Write-Host "   https://$githubUser.github.io/$repoName/" -ForegroundColor Cyan
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 DICA: O deploy acontece automaticamente quando você fizer push!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para atualizações futuras:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Descrição da mudança'" -ForegroundColor Gray
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "Pressione Enter para sair..." -ForegroundColor Gray
Read-Host
