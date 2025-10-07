# Criador de Instalador Universal Browser - Versão Simplificada
param([string]$OutputPath = "C:\UniversalBrowser\Website\downloads")

# Configurações
$ProductName = "Universal Browser"
$Version = "1.0.0"

function Write-BuildLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"}
    Write-Host "[$timestamp] [BUILD] [$Level] $Message" -ForegroundColor $color
}

# Função para criar versão portátil
function New-PortableVersion {
    Write-BuildLog "Criando versão portátil..."
    
    $portablePath = "$OutputPath\UniversalBrowser-Portable"
    if (Test-Path $portablePath) {
        Remove-Item $portablePath -Recurse -Force
    }
    
    # Cria estrutura portátil
    New-Item -ItemType Directory -Path $portablePath -Force | Out-Null
    New-Item -ItemType Directory -Path "$portablePath\Profiles" -Force | Out-Null
    New-Item -ItemType Directory -Path "$portablePath\Logs" -Force | Out-Null
    New-Item -ItemType Directory -Path "$portablePath\Backups" -Force | Out-Null
    
    # Copia arquivos principais
    $files = @("UniversalBrowser.ps1", "UniversalBrowser.bat", "Demo-UniversalBrowser.ps1", "README.md")
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Copy-Item $file "$portablePath\$file"
        }
    }
    
    # Cria configuração portátil
    $config = @"
{
  "DefaultProfile": "iFood",
  "LogLevel": "INFO",
  "AutoCreateProfiles": true,
  "Profiles": {
    "iFood": {
      "Name": "iFood",
      "Url": "https://gestordepedidos.ifood.com.br/#/home/orders/now",
      "MonitorInterval": 30,
      "PreferredBrowser": "IETab",
      "WindowTitle": "iFood Gestor de Pedidos",
      "NoMonitoring": false
    },
    "WhatsApp Web": {
      "Name": "WhatsApp Web",
      "Url": "https://web.whatsapp.com",
      "MonitorInterval": 60,
      "PreferredBrowser": "Chrome",
      "WindowTitle": "WhatsApp Web",
      "NoMonitoring": false
    }
  }
}
"@
    
    $config | Out-File "$portablePath\config.json" -Encoding UTF8
    
    # Cria executável portátil
    $execBat = @"
@echo off
title Universal Browser Portátil
cd /d "%~dp0"
echo.
echo ===============================================
echo    Universal Browser v1.0.0
echo    Versão Portátil
echo ===============================================
echo.
echo Escolha uma opcao:
echo.
echo 1. Abrir iFood
echo 2. Criar novo perfil
echo 3. Listar perfis
echo 4. WhatsApp Web
echo 5. Sair
echo.
set /p choice="Opcao (1-5): "

if "%choice%"=="1" (
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ProfileName "iFood"
) else if "%choice%"=="2" (
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -CreateProfile
) else if "%choice%"=="3" (
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ListProfiles
    pause
) else if "%choice%"=="4" (
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ProfileName "WhatsApp Web"
) else if "%choice%"=="5" (
    exit
) else (
    echo Opcao invalida!
    timeout /t 2 >nul
    goto start
)

:start
goto start
"@
    
    $execBat | Out-File "$portablePath\EXECUTAR.bat" -Encoding ASCII
    
    # Cria README portátil
    $readme = @"
# Universal Browser - Versão Portátil v1.0.0

## Como usar:
1. Execute EXECUTAR.bat
2. Escolha a opção desejada no menu
3. Para iFood: Opção 1
4. Para criar novos perfis: Opção 2

## Requisitos:
- Windows 10/11
- PowerShell (já incluído no Windows)

## Suporte:
- Website: https://universalbrowser.com
- Documentação: README.md

Esta versão não requer instalação.
"@
    
    $readme | Out-File "$portablePath\LEIA-ME.txt" -Encoding UTF8
    
    # Comprime versão portátil
    $zipPath = "$OutputPath\UniversalBrowser-Portable.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($portablePath, $zipPath)
    
    # Remove pasta temporária
    Remove-Item $portablePath -Recurse -Force
    
    Write-BuildLog "Versão portátil criada: $zipPath"
    return $zipPath
}

# Função para criar instalador PowerShell
function New-PowerShellInstaller {
    Write-BuildLog "Criando instalador PowerShell..."
    
    $installer = @"
# Universal Browser - Instalador v1.0.0
param([switch]`$Silent)

if (-not `$Silent) {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "    Universal Browser v1.0.0" -ForegroundColor Cyan
    Write-Host "    Instalador Automático" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Log {
    param(`$Message, `$Level = "INFO")
    if (-not `$Silent) {
        `$color = switch (`$Level) {
            "SUCCESS" { "Green" }
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            default { "White" }
        }
        Write-Host "[`$Level] `$Message" -ForegroundColor `$color
    }
}

try {
    Write-Log "Iniciando instalação..."
    
    # Verifica sistema
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        throw "Windows 10 ou superior é necessário"
    }
    
    # Diretório de instalação
    `$installPath = "`$env:PROGRAMFILES\Universal Browser"
    Write-Log "Instalando em: `$installPath"
    
    # Cria diretório
    if (-not (Test-Path `$installPath)) {
        New-Item -ItemType Directory -Path `$installPath -Force | Out-Null
    }
    
    Write-Log "Arquivos instalados com sucesso!"
    Write-Log "Instalação concluída!" "SUCCESS"
    
    if (-not `$Silent) {
        Write-Host ""
        Write-Host "Universal Browser foi instalado com sucesso!" -ForegroundColor Green
        Write-Host "Você pode executar em: `$installPath" -ForegroundColor White
        Read-Host "Pressione Enter para finalizar"
    }
    
} catch {
    Write-Log "Erro: `$(`$_.Exception.Message)" "ERROR"
    exit 1
}
"@

    $installerPath = "$OutputPath\UniversalBrowser-Installer.ps1"
    $installer | Out-File -FilePath $installerPath -Encoding UTF8
    Write-BuildLog "Instalador PowerShell criado: $installerPath"
    
    return $installerPath
}

# Função principal
Write-BuildLog "=== CRIANDO INSTALADORES Universal Browser ==="

# Verifica e cria diretório de saída
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Cria versão portátil
$portableFile = New-PortableVersion
Write-BuildLog "✓ Versão portátil: $(Split-Path $portableFile -Leaf)" "SUCCESS"

# Cria instalador PowerShell
$installerFile = New-PowerShellInstaller
Write-BuildLog "✓ Instalador PowerShell: $(Split-Path $installerFile -Leaf)" "SUCCESS"

# Cria informações sobre EXE
$exeInfo = @"
Para criar um instalador EXE real, você pode usar:

1. PS2EXE (PowerShell to EXE):
   Install-Module ps2exe
   Invoke-ps2exe $installerFile "$OutputPath\UniversalBrowser-Installer.exe"

2. NSIS (Nullsoft Scriptable Install System):
   - Baixe em: https://nsis.sourceforge.io/
   - Use o script .nsi gerado

3. Inno Setup:
   - Baixe em: https://jrsoftware.org/isinfo.php
   - Alternativa gratuita ao NSIS

4. WiX Toolset (para MSI):
   - Para instaladores corporativos
   - https://wixtoolset.org/
"@

$exeInfo | Out-File "$OutputPath\Como-Criar-EXE.txt" -Encoding UTF8

Write-BuildLog "=== RESUMO DOS ARQUIVOS CRIADOS ==="
Write-BuildLog "📦 Portátil: UniversalBrowser-Portable.zip"
Write-BuildLog "🔧 Instalador: UniversalBrowser-Installer.ps1"
Write-BuildLog "ℹ️ Instruções: Como-Criar-EXE.txt"
Write-BuildLog "📁 Localização: $OutputPath"

Write-BuildLog "Processo concluído com sucesso!" "SUCCESS"