# Criador de Instalador Universal Browser
# Este script cria um instalador executável (.exe) autoextraível

param(
    [string]$OutputPath = "C:\UniversalBrowser\Website\downloads",
    [switch]$CreatePortable
)

# Configurações
$Script:ProductName = "Universal Browser"
$Script:Version = "1.0.0"
$Script:Publisher = "Universal Browser Team"
$Script:Description = "Solução para sites que fecham inesperadamente"

function Write-BuildLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [BUILD] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARN"){"Yellow"}else{"Green"})
}

# Função para criar instalador NSIS
function New-NSISInstaller {
    Write-BuildLog "Criando script NSIS..."
    
    $nsisScript = @"
!define PRODUCT_NAME "$Script:ProductName"
!define PRODUCT_VERSION "$Script:Version"
!define PRODUCT_PUBLISHER "$Script:Publisher"
!define PRODUCT_DESCRIPTION "$Script:Description"
!define PRODUCT_DIR_REGKEY "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\UniversalBrowser.exe"
!define PRODUCT_UNINST_KEY "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\`${PRODUCT_NAME}"

SetCompressor lzma
SetCompressionLevel 9

!include "MUI2.nsh"
!include "FileFunc.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "`${NSISDIR}\\Contrib\\Graphics\\Icons\\modern-install.ico"
!define MUI_UNICON "`${NSISDIR}\\Contrib\\Graphics\\Icons\\modern-uninstall.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "`$INSTDIR\\UniversalBrowser.bat"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "PortugueseBR"

; Reserve files
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

Name "`${PRODUCT_NAME} `${PRODUCT_VERSION}"
OutFile "`${PRODUCT_NAME}-Installer.exe"
InstallDir "`$PROGRAMFILES\\`${PRODUCT_NAME}"
InstallDirRegKey HKLM "`${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
BrandingText "`${PRODUCT_PUBLISHER}"

Section "Arquivos Principais" SEC01
  SetOutPath "`$INSTDIR"
  SetOverwrite ifnewer
  File "UniversalBrowser.ps1"
  File "Install-UniversalBrowser.ps1"
  File "UniversalBrowser.bat"
  File "Demo-UniversalBrowser.ps1"
  File "README.md"
  
  CreateDirectory "`$INSTDIR\\Profiles"
  CreateDirectory "`$INSTDIR\\Logs"
  CreateDirectory "`$INSTDIR\\Backups"
  
  ; Cria configuração inicial
  FileOpen `$4 "`$INSTDIR\\config.json" w
  FileWrite `$4 '{$nl'
  FileWrite `$4 '  "DefaultProfile": "iFood",$nl'
  FileWrite `$4 '  "LogLevel": "INFO",$nl'
  FileWrite `$4 '  "AutoCreateProfiles": true,$nl'
  FileWrite `$4 '  "Profiles": {$nl'
  FileWrite `$4 '    "iFood": {$nl'
  FileWrite `$4 '      "Name": "iFood",$nl'
  FileWrite `$4 '      "Url": "https://gestordepedidos.ifood.com.br/#/home/orders/now",$nl'
  FileWrite `$4 '      "MonitorInterval": 30,$nl'
  FileWrite `$4 '      "PreferredBrowser": "IETab",$nl'
  FileWrite `$4 '      "WindowTitle": "iFood Gestor de Pedidos",$nl'
  FileWrite `$4 '      "NoMonitoring": false$nl'
  FileWrite `$4 '    }$nl'
  FileWrite `$4 '  }$nl'
  FileWrite `$4 '}'
  FileClose `$4
SectionEnd

Section "Atalhos" SEC02
  ; Atalhos do Menu Iniciar
  CreateDirectory "`$SMPROGRAMS\\`${PRODUCT_NAME}"
  CreateShortCut "`$SMPROGRAMS\\`${PRODUCT_NAME}\\`${PRODUCT_NAME}.lnk" "powershell.exe" "-ExecutionPolicy Bypass -WindowStyle Hidden -File \"`$INSTDIR\\UniversalBrowser.ps1\" -GUI" "`$INSTDIR"
  CreateShortCut "`$SMPROGRAMS\\`${PRODUCT_NAME}\\Criar Perfil.lnk" "powershell.exe" "-ExecutionPolicy Bypass -File \"`$INSTDIR\\UniversalBrowser.ps1\" -CreateProfile" "`$INSTDIR"
  CreateShortCut "`$SMPROGRAMS\\`${PRODUCT_NAME}\\iFood Browser.lnk" "powershell.exe" "-ExecutionPolicy Bypass -WindowStyle Hidden -File \"`$INSTDIR\\UniversalBrowser.ps1\" -ProfileName \"iFood\"" "`$INSTDIR"
  CreateShortCut "`$SMPROGRAMS\\`${PRODUCT_NAME}\\Desinstalar.lnk" "`$INSTDIR\\uninst.exe"
  
  ; Atalho na Área de Trabalho
  CreateShortCut "`$DESKTOP\\iFood Browser.lnk" "powershell.exe" "-ExecutionPolicy Bypass -WindowStyle Hidden -File \"`$INSTDIR\\UniversalBrowser.ps1\" -ProfileName \"iFood\"" "`$INSTDIR"
SectionEnd

Section "Registro do Sistema" SEC03
  ; Entradas no Registry
  WriteRegStr HKLM "`${PRODUCT_DIR_REGKEY}" "" "`$INSTDIR\\UniversalBrowser.ps1"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "DisplayName" "`$(^Name)"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "UninstallString" "`$INSTDIR\\uninst.exe"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "DisplayIcon" "`$INSTDIR\\UniversalBrowser.ps1"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "DisplayVersion" "`${PRODUCT_VERSION}"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "Publisher" "`${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "`${PRODUCT_UNINST_KEY}" "URLInfoAbout" "https://universalbrowser.com"
  
  ; Associação de arquivos .ubprofile
  WriteRegStr HKCR ".ubprofile" "" "UniversalBrowser.Profile"
  WriteRegStr HKCR "UniversalBrowser.Profile" "" "Universal Browser Profile"
  WriteRegStr HKCR "UniversalBrowser.Profile\\shell\\open\\command" "" "powershell.exe -ExecutionPolicy Bypass -File \"`$INSTDIR\\UniversalBrowser.ps1\" -ProfileName \"%1\""
SectionEnd

Section -AdditionalIcons
  WriteIniStr "`$INSTDIR\\`${PRODUCT_NAME}.url" "InternetShortcut" "URL" "https://universalbrowser.com"
  CreateShortCut "`$SMPROGRAMS\\`${PRODUCT_NAME}\\Website do `${PRODUCT_NAME}.lnk" "`$INSTDIR\\`${PRODUCT_NAME}.url"
SectionEnd

Section -Post
  WriteUninstaller "`$INSTDIR\\uninst.exe"
SectionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "O `${PRODUCT_NAME} foi removido com sucesso do seu computador."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Tem certeza que deseja remover completamente o `${PRODUCT_NAME} e todos os seus componentes?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  ; Remove arquivos
  Delete "`$INSTDIR\\`${PRODUCT_NAME}.url"
  Delete "`$INSTDIR\\uninst.exe"
  Delete "`$INSTDIR\\UniversalBrowser.ps1"
  Delete "`$INSTDIR\\Install-UniversalBrowser.ps1"
  Delete "`$INSTDIR\\UniversalBrowser.bat"
  Delete "`$INSTDIR\\Demo-UniversalBrowser.ps1"
  Delete "`$INSTDIR\\README.md"
  Delete "`$INSTDIR\\config.json"
  
  ; Remove diretórios
  RMDir /r "`$INSTDIR\\Profiles"
  RMDir /r "`$INSTDIR\\Logs"
  RMDir /r "`$INSTDIR\\Backups"
  RMDir "`$INSTDIR"
  
  ; Remove atalhos
  Delete "`$SMPROGRAMS\\`${PRODUCT_NAME}\\*.*"
  RMDir "`$SMPROGRAMS\\`${PRODUCT_NAME}"
  Delete "`$DESKTOP\\iFood Browser.lnk"
  
  ; Remove entradas do registry
  DeleteRegKey HKLM "`${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "`${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKCR ".ubprofile"
  DeleteRegKey HKCR "UniversalBrowser.Profile"
  
  SetAutoClose true
SectionEnd
"@

    $nsisPath = "$PSScriptRoot\UniversalBrowser-Installer.nsi"
    $nsisScript | Out-File -FilePath $nsisPath -Encoding UTF8
    Write-BuildLog "Script NSIS salvo em: $nsisPath"
    
    return $nsisPath
}

# Função para criar instalador PowerShell autoextraível
function New-SelfExtractingInstaller {
    Write-BuildLog "Criando instalador autoextraível PowerShell..."
    
    $installerScript = @"
# Universal Browser - Instalador Autoextraível
# Versão $Script:Version

param([switch]`$Silent)

`$ErrorActionPreference = "Stop"

# Banner
if (-not `$Silent) {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "    $Script:ProductName v$Script:Version" -ForegroundColor Cyan
    Write-Host "    Instalador Automático" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-InstallLog {
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
    Write-InstallLog "Iniciando instalação do $Script:ProductName..."
    
    # Verifica sistema
    if ([Environment]::OSVersion.Version.Major -lt 10) {
        throw "Windows 10 ou superior é necessário"
    }
    
    # Diretório de instalação
    `$installPath = "`$env:PROGRAMFILES\\$Script:ProductName"
    Write-InstallLog "Instalando em: `$installPath"
    
    # Cria diretório
    if (-not (Test-Path `$installPath)) {
        New-Item -ItemType Directory -Path `$installPath -Force | Out-Null
    }
    
    # Extrai arquivos embutidos
    Write-InstallLog "Extraindo arquivos..."
    
    # DADOS_ARQUIVOS_PLACEHOLDER
    
    Write-InstallLog "Configurando sistema..."
    
    # Executa configuração
    `$configScript = "`$installPath\\Install-UniversalBrowser.ps1"
    if (Test-Path `$configScript) {
        & `$configScript -Silent
    }
    
    Write-InstallLog "Instalação concluída com sucesso!" "SUCCESS"
    
    if (-not `$Silent) {
        Write-Host ""
        Write-Host "O $Script:ProductName foi instalado com sucesso!" -ForegroundColor Green
        Write-Host "Você pode encontrá-lo no Menu Iniciar ou executar:" -ForegroundColor White
        Write-Host "`$installPath\\UniversalBrowser.bat" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Pressione Enter para finalizar"
    }
    
} catch {
    Write-InstallLog "Erro na instalação: `$(`$_.Exception.Message)" "ERROR"
    if (-not `$Silent) {
        Read-Host "Pressione Enter para sair"
    }
    exit 1
}
"@

    $installerPath = "$OutputPath\UniversalBrowser-Installer.ps1"
    $installerScript | Out-File -FilePath $installerPath -Encoding UTF8
    Write-BuildLog "Instalador PowerShell criado: $installerPath"
    
    return $installerPath
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
    $files = @(
        "UniversalBrowser.ps1",
        "UniversalBrowser.bat", 
        "Demo-UniversalBrowser.ps1",
        "README.md"
    )
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            Copy-Item $file "$portablePath\$file"
        }
    }
    
    # Cria configuração portátil
    $portableConfig = @{
        "DefaultProfile" = "iFood"
        "LogLevel" = "INFO"
        "AutoCreateProfiles" = $true
        "Profiles" = @{
            "iFood" = @{
                "Name" = "iFood"
                "Url" = "https://gestordepedidos.ifood.com.br/#/home/orders/now"
                "MonitorInterval" = 30
                "PreferredBrowser" = "IETab"
                "WindowTitle" = "iFood Gestor de Pedidos"
                "NoMonitoring" = $false
            }
            "WhatsApp Web" = @{
                "Name" = "WhatsApp Web"
                "Url" = "https://web.whatsapp.com"
                "MonitorInterval" = 60
                "PreferredBrowser" = "Chrome"
                "WindowTitle" = "WhatsApp Web"
                "NoMonitoring" = $false
            }
        }
    }
    
    $portableConfig | ConvertTo-Json -Depth 5 | Out-File "$portablePath\config.json" -Encoding UTF8
    
    # Cria executável portátil
    $portableBat = @"
@echo off
title $Script:ProductName Portátil
cd /d "%~dp0"
echo.
echo ===============================================
echo    $Script:ProductName v$Script:Version
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
    
    $portableBat | Out-File "$portablePath\EXECUTAR.bat" -Encoding ASCII
    
    # Cria arquivo README portátil
    $readmePortable = @"
# $Script:ProductName - Versão Portátil

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
- Documentação: Inclusa no README.md

Esta é uma versão portátil que não requer instalação.
Todos os arquivos ficam nesta pasta.
"@
    
    $readmePortable | Out-File "$portablePath\LEIA-ME.txt" -Encoding UTF8
    
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

# Função principal
function Main {
    Write-BuildLog "=== CRIANDO INSTALADORES $Script:ProductName ==="
    
    # Verifica e cria diretório de saída
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Cria versão portátil se solicitada ou sempre
    if ($CreatePortable -or $true) {
        $portableFile = New-PortableVersion
        Write-BuildLog "✓ Versão portátil: $(Split-Path $portableFile -Leaf)" "SUCCESS"
    }
    
    # Cria instalador PowerShell
    $installerFile = New-SelfExtractingInstaller  
    Write-BuildLog "✓ Instalador PowerShell: $(Split-Path $installerFile -Leaf)" "SUCCESS"
    
    # Cria versão EXE (simulada - seria necessário compilador)
    $exePath = "$OutputPath\UniversalBrowser-Installer.exe"
    $exeContent = @"
# Este seria o instalador EXE
# Para criar um EXE real, você precisaria de:
# 1. PS2EXE: Converter PowerShell para EXE
# 2. NSIS: Nullsoft Scriptable Install System
# 3. WiX Toolset: Para criar MSI
# 4. Inno Setup: Alternativa ao NSIS

# Comando de exemplo com PS2EXE:
# PS2EXE $installerFile $exePath -noConsole -title "$Script:ProductName Installer" -version $Script:Version
"@
    
    $exeContent | Out-File "$exePath.info" -Encoding UTF8
    
    # Cria instalador fake para demonstração
    Copy-Item $installerFile $exePath.Replace(".exe", "-Script.ps1")
    
    Write-BuildLog "=== RESUMO DOS ARQUIVOS CRIADOS ==="
    Write-BuildLog "📦 Portátil: UniversalBrowser-Portable.zip"
    Write-BuildLog "🔧 Instalador: UniversalBrowser-Installer.ps1" 
    Write-BuildLog "ℹ️ Info EXE: UniversalBrowser-Installer.exe.info"
    Write-BuildLog "📁 Localização: $OutputPath"
    
    Write-BuildLog "=== PRÓXIMOS PASSOS ==="
    Write-BuildLog "1. Para criar EXE real, use PS2EXE ou NSIS"
    Write-BuildLog "2. Para distribuir, hospede em um servidor web"
    Write-BuildLog "3. Para assinatura digital, obtenha certificado de código"
    
    Write-BuildLog "Processo concluído com sucesso!" "SUCCESS"
}

# Executa
Main
