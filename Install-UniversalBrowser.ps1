# Instalador do Universal Browser
# Instala e configura automaticamente o sistema no Windows

param(
    [switch]$Uninstall,
    [switch]$Repair,
    [switch]$Silent,
    [string]$InstallPath = "C:\UniversalBrowser"
)

# Configurações do instalador
$Script:ProductName = "Universal Browser"
$Script:Version = "1.0.0"
$Script:Publisher = "Universal Browser Team"
$Script:InstallPath = $InstallPath
$Script:StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Universal Browser"
$Script:RegistryPath = "HKCU:\Software\UniversalBrowser"

# Função para logging do instalador
function Write-InstallerLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [INSTALLER] [$Level] $Message"
    if (-not $Silent) { Write-Host $logEntry }
    
    $logFile = "$env:TEMP\UniversalBrowser-Install.log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

# Função para verificar privilégios administrativos
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para criar estrutura de diretórios
function New-DirectoryStructure {
    Write-InstallerLog "Criando estrutura de diretórios..."
    
    $directories = @(
        $Script:InstallPath,
        "$Script:InstallPath\Profiles", 
        "$Script:InstallPath\Logs",
        "$Script:InstallPath\Backups",
        $Script:StartMenuPath
    )
    
    foreach ($dir in $directories) {
        try {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-InstallerLog "Diretório criado: $dir"
            }
        } catch {
            Write-InstallerLog "Erro ao criar diretório $dir`: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    return $true
}

# Função para copiar arquivos
function Copy-Files {
    Write-InstallerLog "Copiando arquivos do sistema..."
    
    $sourceFiles = @{
        "UniversalBrowser.ps1" = "Script principal"
        "UniversalBrowser-GUI.ps1" = "Interface gráfica"
        "README.md" = "Documentação"
    }
    
    foreach ($file in $sourceFiles.Keys) {
        try {
            $sourcePath = "$PSScriptRoot\$file"
            $destPath = "$Script:InstallPath\$file"
            
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath $destPath -Force
                Write-InstallerLog "Arquivo copiado: $file - $($sourceFiles[$file])"
            } else {
                Write-InstallerLog "Arquivo fonte não encontrado: $file" "WARN"
            }
        } catch {
            Write-InstallerLog "Erro ao copiar $file`: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    return $true
}

# Função para criar perfis padrão
function New-DefaultProfiles {
    Write-InstallerLog "Criando perfis padrão..."
    
    $profiles = @{
        "iFood" = @{
            Name = "iFood"
            Url = "https://gestordepedidos.ifood.com.br/#/home/orders/now"
            MonitorInterval = 30
            PreferredBrowser = "IETab"
            WindowTitle = "iFood Gestor de Pedidos"
            NoMonitoring = $false
        }
        "WhatsApp Web" = @{
            Name = "WhatsApp Web"
            Url = "https://web.whatsapp.com"
            MonitorInterval = 60
            PreferredBrowser = "Chrome"
            WindowTitle = "WhatsApp Web"
            NoMonitoring = $false
        }
        "Gmail" = @{
            Name = "Gmail"
            Url = "https://mail.google.com"
            MonitorInterval = 60
            PreferredBrowser = "Auto"
            WindowTitle = "Gmail"
            NoMonitoring = $true
        }
        "Office 365" = @{
            Name = "Office 365"
            Url = "https://portal.office.com"
            MonitorInterval = 30
            PreferredBrowser = "Edge"
            WindowTitle = "Office 365"
            NoMonitoring = $false
        }
    }
    
    $config = @{
        DefaultProfile = "iFood"
        LogLevel = "INFO"
        AutoCreateProfiles = $true
        Profiles = $profiles
    }
    
    try {
        $configPath = "$Script:InstallPath\config.json"
        $config | ConvertTo-Json -Depth 5 | Out-File $configPath -Encoding UTF8
        Write-InstallerLog "Perfis padrão criados em $configPath"
        return $true
    } catch {
        Write-InstallerLog "Erro ao criar perfis padrão: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Função para criar atalhos
function New-Shortcuts {
    Write-InstallerLog "Criando atalhos..."
    
    try {
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Atalho principal no Menu Iniciar
        $shortcut = $WScriptShell.CreateShortcut("$Script:StartMenuPath\Universal Browser.lnk")
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script:InstallPath\UniversalBrowser.ps1`" -GUI"
        $shortcut.Description = "Universal Browser - Solução para sites que fecham"
        $shortcut.WorkingDirectory = $Script:InstallPath
        $shortcut.WindowStyle = 7  # Minimized
        $shortcut.Save()
        Write-InstallerLog "Atalho criado: Menu Iniciar"
        
        # Atalho para criar perfis
        $shortcut2 = $WScriptShell.CreateShortcut("$Script:StartMenuPath\Criar Perfil.lnk")
        $shortcut2.TargetPath = "powershell.exe"
        $shortcut2.Arguments = "-ExecutionPolicy Bypass -File `"$Script:InstallPath\UniversalBrowser.ps1`" -CreateProfile"
        $shortcut2.Description = "Criar novo perfil de site"
        $shortcut2.WorkingDirectory = $Script:InstallPath
        $shortcut2.Save()
        Write-InstallerLog "Atalho criado: Criar Perfil"
        
        # Atalhos para perfis específicos na área de trabalho
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        
        $desktopShortcut = $WScriptShell.CreateShortcut("$desktopPath\iFood Browser.lnk")
        $desktopShortcut.TargetPath = "powershell.exe"
        $desktopShortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script:InstallPath\UniversalBrowser.ps1`" -ProfileName `"iFood`""
        $desktopShortcut.Description = "iFood Gestor de Pedidos"
        $desktopShortcut.WorkingDirectory = $Script:InstallPath
        $desktopShortcut.WindowStyle = 7
        $desktopShortcut.Save()
        Write-InstallerLog "Atalho criado: Área de trabalho - iFood"
        
        return $true
    } catch {
        Write-InstallerLog "Erro ao criar atalhos: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Função para criar entradas no registro
function New-RegistryEntries {
    Write-InstallerLog "Criando entradas no registro..."
    
    try {
        # Cria chave principal
        if (-not (Test-Path $Script:RegistryPath)) {
            New-Item -Path $Script:RegistryPath -Force | Out-Null
        }
        
        # Define valores
        Set-ItemProperty -Path $Script:RegistryPath -Name "InstallPath" -Value $Script:InstallPath
        Set-ItemProperty -Path $Script:RegistryPath -Name "Version" -Value $Script:Version
        Set-ItemProperty -Path $Script:RegistryPath -Name "InstallDate" -Value (Get-Date -Format "yyyy-MM-dd")
        Set-ItemProperty -Path $Script:RegistryPath -Name "Publisher" -Value $Script:Publisher
        
        Write-InstallerLog "Entradas do registro criadas"
        return $true
    } catch {
        Write-InstallerLog "Erro ao criar entradas no registro: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Função para configurar associações de arquivo
function Set-FileAssociations {
    Write-InstallerLog "Configurando associações de arquivo..."
    
    try {
        # Associa arquivos .ubprofile com o Universal Browser
        $assocPath = "HKCU:\Software\Classes\.ubprofile"
        if (-not (Test-Path $assocPath)) {
            New-Item -Path $assocPath -Force | Out-Null
        }
        Set-ItemProperty -Path $assocPath -Name "(default)" -Value "UniversalBrowser.Profile"
        
        $commandPath = "HKCU:\Software\Classes\UniversalBrowser.Profile\shell\open\command"
        if (-not (Test-Path $commandPath)) {
            New-Item -Path $commandPath -Force | Out-Null
        }
        Set-ItemProperty -Path $commandPath -Name "(default)" -Value "`"powershell.exe`" -ExecutionPolicy Bypass -File `"$Script:InstallPath\UniversalBrowser.ps1`" -ProfileName `"%1`""
        
        Write-InstallerLog "Associações de arquivo configuradas"
        return $true
    } catch {
        Write-InstallerLog "Erro ao configurar associações: $($_.Exception.Message)" "WARN"
        return $true  # Não é crítico
    }
}

# Função para criar arquivo batch de acesso rápido
function New-BatchFile {
    Write-InstallerLog "Criando arquivo batch..."
    
    $batchContent = @"
@echo off
title Universal Browser
echo.
echo ===============================================
echo        Universal Browser v$Script:Version
echo ===============================================
echo.
echo Escolha uma opcao:
echo.
echo 1. Abrir iFood
echo 2. Criar novo perfil
echo 3. Listar perfis existentes
echo 4. Interface grafica
echo 5. Sair
echo.
set /p choice="Opcao (1-5): "

if "%choice%"=="1" (
    cd /d "$Script:InstallPath"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ProfileName "iFood"
) else if "%choice%"=="2" (
    cd /d "$Script:InstallPath"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -CreateProfile
) else if "%choice%"=="3" (
    cd /d "$Script:InstallPath"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ListProfiles
    pause
) else if "%choice%"=="4" (
    cd /d "$Script:InstallPath"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -GUI
) else if "%choice%"=="5" (
    exit
) else (
    echo Opcao invalida!
    timeout /t 2 >nul
    goto start
)

:start
goto :eof
"@
    
    try {
        $batchPath = "$Script:InstallPath\UniversalBrowser.bat"
        $batchContent | Out-File -FilePath $batchPath -Encoding ASCII
        Write-InstallerLog "Arquivo batch criado: $batchPath"
        return $true
    } catch {
        Write-InstallerLog "Erro ao criar arquivo batch: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Função para desinstalar
function Uninstall-UniversalBrowser {
    Write-InstallerLog "=== INICIANDO DESINSTALAÇÃO ==="
    
    # Remove atalhos
    if (Test-Path $Script:StartMenuPath) {
        Remove-Item $Script:StartMenuPath -Recurse -Force
        Write-InstallerLog "Atalhos do Menu Iniciar removidos"
    }
    
    $desktopShortcut = "[Environment]::GetFolderPath('Desktop')\iFood Browser.lnk"
    if (Test-Path $desktopShortcut) {
        Remove-Item $desktopShortcut -Force
        Write-InstallerLog "Atalho da área de trabalho removido"
    }
    
    # Remove entradas do registro
    if (Test-Path $Script:RegistryPath) {
        Remove-Item $Script:RegistryPath -Recurse -Force
        Write-InstallerLog "Entradas do registro removidas"
    }
    
    # Remove arquivos (opcional - pergunta ao usuário)
    if (-not $Silent) {
        $removeFiles = Read-Host "Remover também os arquivos e perfis? (s/N)"
        if ($removeFiles -eq 's' -or $removeFiles -eq 'S') {
            if (Test-Path $Script:InstallPath) {
                Remove-Item $Script:InstallPath -Recurse -Force
                Write-InstallerLog "Arquivos removidos: $Script:InstallPath"
            }
        }
    }
    
    Write-InstallerLog "Desinstalação concluída"
}

# Função para reparar instalação
function Repair-Installation {
    Write-InstallerLog "=== REPARANDO INSTALAÇÃO ==="
    
    # Verifica e recria estrutura de diretórios
    New-DirectoryStructure
    
    # Recria atalhos se necessário
    if (-not (Test-Path "$Script:StartMenuPath\Universal Browser.lnk")) {
        New-Shortcuts
    }
    
    # Verifica configuração
    $configPath = "$Script:InstallPath\config.json"
    if (-not (Test-Path $configPath)) {
        New-DefaultProfiles
    }
    
    Write-InstallerLog "Reparação concluída"
}

# Função principal do instalador
function Main {
    if (-not $Silent) {
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host "     $Script:ProductName v$Script:Version" -ForegroundColor Cyan  
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-InstallerLog "=== INICIANDO INSTALAÇÃO ==="
    Write-InstallerLog "Versão: $Script:Version"
    Write-InstallerLog "Caminho de instalação: $Script:InstallPath"
    
    # Verifica modo de operação
    if ($Uninstall) {
        Uninstall-UniversalBrowser
        return
    }
    
    if ($Repair) {
        Repair-Installation
        return
    }
    
    # Verifica se já está instalado
    if (Test-Path "$Script:InstallPath\UniversalBrowser.ps1") {
        if (-not $Silent) {
            $overwrite = Read-Host "Universal Browser já está instalado. Sobrescrever? (s/N)"
            if ($overwrite -ne 's' -and $overwrite -ne 'S') {
                Write-InstallerLog "Instalação cancelada pelo usuário"
                return
            }
        }
    }
    
    # Executa passos de instalação
    $steps = @(
        @{Name="Criando estrutura"; Function={New-DirectoryStructure}},
        @{Name="Copiando arquivos"; Function={Copy-Files}}, 
        @{Name="Criando perfis padrão"; Function={New-DefaultProfiles}},
        @{Name="Criando atalhos"; Function={New-Shortcuts}},
        @{Name="Configurando registro"; Function={New-RegistryEntries}},
        @{Name="Configurando associações"; Function={Set-FileAssociations}},
        @{Name="Criando arquivo batch"; Function={New-BatchFile}}
    )
    
    $success = $true
    foreach ($step in $steps) {
        Write-InstallerLog "Executando: $($step.Name)..."
        if (-not (& $step.Function)) {
            $success = $false
            break
        }
    }
    
    if ($success) {
        Write-InstallerLog "=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ==="
        if (-not $Silent) {
            Write-Host "`nInstalação concluída com sucesso!" -ForegroundColor Green
            Write-Host "Você pode iniciar o Universal Browser através do Menu Iniciar" -ForegroundColor White
            Write-Host "ou executando o arquivo: $Script:InstallPath\UniversalBrowser.bat" -ForegroundColor White
            Write-Host ""
            Write-Host "Log de instalação: $env:TEMP\UniversalBrowser-Install.log" -ForegroundColor Gray
        }
    } else {
        Write-InstallerLog "=== INSTALAÇÃO FALHOU ===" "ERROR"
        if (-not $Silent) {
            Write-Host "`nInstalação falhou! Verifique o log para mais detalhes." -ForegroundColor Red
        }
    }
}

# Executa instalador
Main