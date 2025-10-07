# Demonstração do Universal Browser
# Este script mostra todos os recursos disponíveis

param([switch]$FullDemo)

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "      Universal Browser v1.0.0 - DEMO" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Demonstração básica
Write-Host "=== DEMONSTRAÇÃO BÁSICA ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Listando perfis disponíveis:" -ForegroundColor Green
& ".\UniversalBrowser.ps1" -ListProfiles
Write-Host ""

Write-Host "2. Testando abertura do iFood (sem monitoramento):" -ForegroundColor Green
& ".\UniversalBrowser.ps1" -ProfileName "Ifood" -NoMonitoring
Write-Host ""

Write-Host "3. Testando URL direta com Chrome:" -ForegroundColor Green  
& ".\UniversalBrowser.ps1" -Url "https://www.google.com" -UseChrome -NoMonitoring
Write-Host ""

if ($FullDemo) {
    Write-Host "=== DEMONSTRAÇÃO COMPLETA ===" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "4. Criando perfil de teste:" -ForegroundColor Green
    $profileData = @"
Demo Site
https://httpbin.org/delay/1
15
Auto
n
"@
    
    $profileData | & ".\UniversalBrowser.ps1" -CreateProfile
    Write-Host ""
    
    Write-Host "5. Testando perfil criado:" -ForegroundColor Green
    & ".\UniversalBrowser.ps1" -ProfileName "Demo Site" -NoMonitoring
    Write-Host ""
    
    Write-Host "6. Listando perfis atualizados:" -ForegroundColor Green
    & ".\UniversalBrowser.ps1" -ListProfiles
    Write-Host ""
}

Write-Host "=== COMANDOS ÚTEIS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usar perfil específico:" -ForegroundColor White
Write-Host "  .\UniversalBrowser.ps1 -ProfileName 'Ifood'" -ForegroundColor Gray
Write-Host ""
Write-Host "Abrir URL direta:" -ForegroundColor White
Write-Host "  .\UniversalBrowser.ps1 -Url 'https://site.com' -UseEdge" -ForegroundColor Gray
Write-Host ""
Write-Host "Criar novo perfil:" -ForegroundColor White
Write-Host "  .\UniversalBrowser.ps1 -CreateProfile" -ForegroundColor Gray
Write-Host ""
Write-Host "Interface interativa:" -ForegroundColor White
Write-Host "  .\UniversalBrowser.bat" -ForegroundColor Gray
Write-Host ""

Write-Host "=== RECURSOS AVANÇADOS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "• Sistema de perfis ilimitados" -ForegroundColor White
Write-Host "• Suporte a 5+ navegadores" -ForegroundColor White
Write-Host "• Monitoramento automático customizável" -ForegroundColor White
Write-Host "• Logs detalhados por perfil" -ForegroundColor White
Write-Host "• Instalador automático" -ForegroundColor White
Write-Host "• Atalhos no sistema" -ForegroundColor White
Write-Host ""

Write-Host "=== LOGS E CONFIGURAÇÃO ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Configuração:" -ForegroundColor White
Write-Host "  C:\UniversalBrowser\config.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Logs:" -ForegroundColor White
Write-Host "  C:\UniversalBrowser\Logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "Log de hoje:" -ForegroundColor White
$todayLog = "C:\UniversalBrowser\Logs\universal-browser-$(Get-Date -Format 'yyyy-MM-dd').log"
Write-Host "  $todayLog" -ForegroundColor Gray

if (Test-Path $todayLog) {
    Write-Host ""
    Write-Host "Últimas 5 linhas do log:" -ForegroundColor Green
    Get-Content $todayLog | Select-Object -Last 5 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "         Demonstração concluída!" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan