# Universal Browser - Solução para sites que fecham inesperadamente
# Versão Universal - Funciona com qualquer site
# Autor: Assistant AI

param(
    [string]$Url = "",
    [string]$ProfileName = "",
    [int]$MonitorInterval = 30,
    [switch]$NoMonitoring,
    [switch]$UseChrome,
    [switch]$UseEdge, 
    [switch]$UseIE,
    [switch]$UseFirefox,
    [string]$BrowserPath = "",
    [string]$WindowTitle = "Universal Browser",
    [switch]$GUI,
    [switch]$ListProfiles,
    [switch]$CreateProfile
)

# Configurações globais
$Script:AppPath = "C:\UniversalBrowser"
$Script:ProfilesPath = "$AppPath\Profiles"
$Script:LogsPath = "$AppPath\Logs" 
$Script:IETabHelperPath = "C:\Users\likel\AppData\Local\IE Tab\18.8.19.1\ietabhelper.exe"
$Script:ConfigFile = "$AppPath\config.json"

# Configuração padrão
$Script:DefaultConfig = @{
    "DefaultProfile" = "Default"
    "LogLevel" = "INFO"
    "AutoCreateProfiles" = $true
    "Profiles" = @{
        "Default" = @{
            "Name" = "Default"
            "Url" = "about:blank"
            "MonitorInterval" = 30
            "PreferredBrowser" = "Auto"
            "WindowTitle" = "Universal Browser"
            "NoMonitoring" = $false
        }
    }
}

# Função para logging
function Write-Log {
    param($Message, $Level = "INFO", $ProfileName = "SYSTEM")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$ProfileName] $Message"
    Write-Host $logEntry
    
    $logFile = "$Script:LogsPath\universal-browser-$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

# Função para carregar configuração
function Load-Config {
    try {
        if (Test-Path $Script:ConfigFile) {
            $config = Get-Content $Script:ConfigFile -Raw | ConvertFrom-Json
            Write-Log "Configuração carregada de $Script:ConfigFile"
            return $config
        } else {
            Write-Log "Arquivo de configuração não encontrado. Criando padrão..." "WARN"
            Save-Config $Script:DefaultConfig
            return $Script:DefaultConfig
        }
    } catch {
        Write-Log "Erro ao carregar configuração: $($_.Exception.Message)" "ERROR"
        return $Script:DefaultConfig
    }
}

# Função para salvar configuração
function Save-Config {
    param($Config)
    try {
        $Config | ConvertTo-Json -Depth 5 | Out-File $Script:ConfigFile -Encoding UTF8
        Write-Log "Configuração salva em $Script:ConfigFile"
        return $true
    } catch {
        Write-Log "Erro ao salvar configuração: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Função para listar perfis
function Get-Profiles {
    $config = Load-Config
    return $config.Profiles.PSObject.Properties | ForEach-Object {
        $_.Value
    }
}

# Função para obter perfil específico
function Get-Profile {
    param($Name)
    $config = Load-Config
    if ($config.Profiles.$Name) {
        return $config.Profiles.$Name
    }
    return $null
}

# Função para criar/atualizar perfil
function Set-Profile {
    param(
        [string]$Name,
        [string]$Url,
        [int]$MonitorInterval = 30,
        [string]$PreferredBrowser = "Auto",
        [string]$WindowTitle = "",
        [bool]$NoMonitoring = $false
    )
    
    $config = Load-Config
    
    if (-not $WindowTitle) {
        $WindowTitle = $Name
    }
    
    $profile = @{
        "Name" = $Name
        "Url" = $Url
        "MonitorInterval" = $MonitorInterval
        "PreferredBrowser" = $PreferredBrowser
        "WindowTitle" = $WindowTitle
        "NoMonitoring" = $NoMonitoring
    }
    
    $config.Profiles.$Name = $profile
    
    if (Save-Config $config) {
        Write-Log "Perfil '$Name' criado/atualizado com sucesso"
        return $true
    }
    return $false
}

# Função para verificar se um processo está rodando
function Test-ProcessRunning {
    param($ProcessName)
    return (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) -ne $null
}

# Função para detectar navegadores disponíveis
function Get-AvailableBrowsers {
    $browsers = @()
    
    # Chrome
    $chromeExe = Get-Command "chrome.exe" -ErrorAction SilentlyContinue
    if ($chromeExe) {
        $browsers += @{Name="Chrome"; Command="chrome.exe"; Type="Standard"}
    }
    
    # Edge
    $edgeExe = Get-Command "msedge.exe" -ErrorAction SilentlyContinue
    if ($edgeExe) {
        $browsers += @{Name="Edge"; Command="msedge.exe"; Type="Standard"}
    }
    
    # Firefox
    $firefoxExe = Get-Command "firefox.exe" -ErrorAction SilentlyContinue
    if ($firefoxExe) {
        $browsers += @{Name="Firefox"; Command="firefox.exe"; Type="Standard"}
    }
    
    # Internet Explorer
    $ieExe = Get-Command "iexplore.exe" -ErrorAction SilentlyContinue
    if ($ieExe) {
        $browsers += @{Name="IE"; Command="iexplore.exe"; Type="Standard"}
    }
    
    # IE Tab Helper
    if (Test-Path $Script:IETabHelperPath) {
        $browsers += @{Name="IETab"; Command=$Script:IETabHelperPath; Type="Helper"}
    }
    
    return $browsers
}

# Função para iniciar navegador
function Start-Browser {
    param($Method, $Url, $ProfileName = "Default")
    
    Write-Log "Tentando abrir navegador com método: $Method" "INFO" $ProfileName
    
    try {
        switch ($Method) {
            "Chrome" {
                Write-Log "Iniciando Google Chrome..." "INFO" $ProfileName
                $chromeArgs = @(
                    "--new-window",
                    "--disable-web-security",
                    "--disable-features=VizDisplayCompositor",
                    $Url
                )
                Start-Process "chrome.exe" -ArgumentList $chromeArgs
                return "chrome"
            }
            "Edge" {
                Write-Log "Iniciando Microsoft Edge..." "INFO" $ProfileName
                Start-Process "msedge.exe" -ArgumentList "--new-window", $Url
                return "msedge"
            }
            "Firefox" {
                Write-Log "Iniciando Firefox..." "INFO" $ProfileName
                Start-Process "firefox.exe" -ArgumentList "-new-window", $Url
                return "firefox"
            }
            "IE" {
                Write-Log "Iniciando Internet Explorer..." "INFO" $ProfileName
                Start-Process "iexplore.exe" -ArgumentList $Url
                return "iexplore"
            }
            "IETab" {
                Write-Log "Iniciando com IE Tab Helper..." "INFO" $ProfileName
                if (Test-Path $Script:IETabHelperPath) {
                    Start-Process $Script:IETabHelperPath -ArgumentList $Url
                    return "ietabhelper"
                } else {
                    throw "IE Tab Helper não encontrado"
                }
            }
            "Custom" {
                if ($BrowserPath -and (Test-Path $BrowserPath)) {
                    Write-Log "Iniciando navegador customizado: $BrowserPath" "INFO" $ProfileName
                    Start-Process $BrowserPath -ArgumentList $Url
                    return "custom"
                } else {
                    throw "Caminho do navegador customizado inválido"
                }
            }
            default {
                Write-Log "Usando navegador padrão do sistema..." "INFO" $ProfileName
                Start-Process $Url
                return "default"
            }
        }
    } catch {
        Write-Log "Erro ao iniciar navegador com método $Method : $($_.Exception.Message)" "ERROR" $ProfileName
        return $null
    }
}

# Função para monitoramento inteligente
function Start-Monitoring {
    param($ProcessName, $Profile)
    
    Write-Log "Iniciando monitoramento do processo: $ProcessName" "INFO" $Profile.Name
    
    while ($true) {
        Start-Sleep -Seconds $Profile.MonitorInterval
        
        if (-not (Test-ProcessRunning $ProcessName)) {
            Write-Log "Processo $ProcessName não está mais rodando. Reiniciando..." "WARN" $Profile.Name
            
            # Determina ordem de preferência de navegadores
            $browsers = Get-AvailableBrowsers
            $methods = @()
            
            # Prioriza navegador preferido
            if ($Profile.PreferredBrowser -ne "Auto") {
                $methods += $Profile.PreferredBrowser
            }
            
            # Adiciona outros navegadores disponíveis
            $browsers | ForEach-Object { $methods += $_.Name }
            $methods += "Default"
            
            $restarted = $false
            foreach ($method in $methods) {
                $newProcess = Start-Browser $method $Profile.Url $Profile.Name
                if ($newProcess) {
                    $ProcessName = $newProcess
                    $restarted = $true
                    Write-Log "Navegador reiniciado com sucesso usando método: $method" "INFO" $Profile.Name
                    break
                }
            }
            
            if (-not $restarted) {
                Write-Log "Falha ao reiniciar o navegador com todos os métodos" "ERROR" $Profile.Name
                break
            }
        } else {
            Write-Log "Processo $ProcessName rodando normalmente" "INFO" $Profile.Name
        }
    }
}

# Função para criar perfil interativamente
function New-InteractiveProfile {
    Write-Host "`n=== CRIANDO NOVO PERFIL ===" -ForegroundColor Cyan
    
    $name = Read-Host "Nome do perfil"
    $url = Read-Host "URL do site"
    $interval = Read-Host "Intervalo de monitoramento (segundos) [30]"
    if (-not $interval) { $interval = 30 }
    
    Write-Host "`nNavegadores disponíveis:"
    $browsers = Get-AvailableBrowsers
    $browsers | ForEach-Object -Begin {$i=1} { Write-Host "$i. $($_.Name)"; $i++ }
    Write-Host "$i. Auto (detectar automaticamente)"
    
    $browserChoice = Read-Host "Escolha o navegador preferido [Auto]"
    $preferredBrowser = "Auto"
    if ($browserChoice -and $browserChoice -match '^\d+$') {
        $index = [int]$browserChoice - 1
        if ($index -ge 0 -and $index -lt $browsers.Count) {
            $preferredBrowser = $browsers[$index].Name
        }
    }
    
    $noMonitoring = (Read-Host "Desabilitar monitoramento automático? (s/N)") -eq 's'
    
    if (Set-Profile -Name $name -Url $url -MonitorInterval $interval -PreferredBrowser $preferredBrowser -NoMonitoring $noMonitoring) {
        Write-Host "Perfil '$name' criado com sucesso!" -ForegroundColor Green
        return $name
    } else {
        Write-Host "Erro ao criar perfil" -ForegroundColor Red
        return $null
    }
}

# Função principal
function Main {
    Write-Log "=== INICIANDO UNIVERSAL BROWSER ===" 
    
    # Verifica se precisa mostrar GUI
    if ($GUI) {
        Show-GUI
        return
    }
    
    # Lista perfis se solicitado
    if ($ListProfiles) {
        Write-Host "`n=== PERFIS DISPONÍVEIS ===" -ForegroundColor Cyan
        $profiles = Get-Profiles
        $profiles | ForEach-Object {
            Write-Host "• $($_.Name) - $($_.Url)" -ForegroundColor White
        }
        return
    }
    
    # Cria perfil se solicitado
    if ($CreateProfile) {
        New-InteractiveProfile
        return
    }
    
    # Determina perfil a usar
    $profile = $null
    if ($ProfileName) {
        $profile = Get-Profile $ProfileName
        if (-not $profile) {
            Write-Log "Perfil '$ProfileName' não encontrado" "ERROR"
            return
        }
    } elseif ($Url) {
        # Cria perfil temporário
        $profile = @{
            Name = "Temporary"
            Url = $Url
            MonitorInterval = $MonitorInterval
            PreferredBrowser = "Auto"
            WindowTitle = $WindowTitle
            NoMonitoring = $NoMonitoring.IsPresent
        }
    } else {
        # Usa perfil padrão
        $profile = Get-Profile "Default"
        if (-not $profile) {
            Write-Log "Perfil padrão não encontrado. Execute com -CreateProfile para criar um" "ERROR"
            return
        }
    }
    
    # Override de parâmetros se fornecidos
    if ($UseChrome) { $profile.PreferredBrowser = "Chrome" }
    elseif ($UseEdge) { $profile.PreferredBrowser = "Edge" }
    elseif ($UseFirefox) { $profile.PreferredBrowser = "Firefox" }
    elseif ($UseIE) { $profile.PreferredBrowser = "IE" }
    elseif ($BrowserPath) { $profile.PreferredBrowser = "Custom" }
    
    if ($NoMonitoring) { $profile.NoMonitoring = $true }
    if ($MonitorInterval -ne 30) { $profile.MonitorInterval = $MonitorInterval }
    
    Write-Log "Usando perfil: $($profile.Name)" "INFO" $profile.Name
    Write-Log "URL: $($profile.Url)" "INFO" $profile.Name
    Write-Log "Navegador preferido: $($profile.PreferredBrowser)" "INFO" $profile.Name
    
    # Determina método de abertura
    $method = $profile.PreferredBrowser
    if ($method -eq "Auto") {
        $browsers = Get-AvailableBrowsers
        if ($browsers.Count -gt 0) {
            # Prioriza IE Tab se disponível, senão usa o primeiro disponível
            $ieTab = $browsers | Where-Object { $_.Name -eq "IETab" }
            if ($ieTab) {
                $method = "IETab"
            } else {
                $method = $browsers[0].Name
            }
        } else {
            $method = "Default"
        }
    }
    
    # Inicia navegador
    $processName = Start-Browser $method $profile.Url $profile.Name
    
    if (-not $processName) {
        Write-Log "Falha ao iniciar navegador. Tentando métodos alternativos..." "ERROR" $profile.Name
        
        $browsers = Get-AvailableBrowsers
        $methods = $browsers.Name + @("Default")
        
        foreach ($altMethod in $methods) {
            if ($altMethod -ne $method) {
                $processName = Start-Browser $altMethod $profile.Url $profile.Name
                if ($processName) {
                    break
                }
            }
        }
    }
    
    if (-not $processName) {
        Write-Log "Não foi possível iniciar nenhum navegador" "ERROR" $profile.Name
        exit 1
    }
    
    Write-Log "Navegador iniciado com sucesso. Processo: $processName" "INFO" $profile.Name
    
    # Inicia monitoramento se habilitado
    if (-not $profile.NoMonitoring) {
        Write-Log "Iniciando monitoramento..." "INFO" $profile.Name
        Start-Monitoring $processName $profile
    } else {
        Write-Log "Monitoramento desabilitado. Script finalizado." "INFO" $profile.Name
    }
}

# Interface gráfica simples (placeholder - será expandida)
function Show-GUI {
    Write-Host "GUI Mode - Em desenvolvimento..." -ForegroundColor Yellow
    Write-Host "Use os comandos de linha por enquanto:"
    Write-Host "  -ListProfiles    - Lista todos os perfis"
    Write-Host "  -CreateProfile   - Cria novo perfil"
    Write-Host "  -ProfileName X   - Executa perfil específico"
}

# Executa função principal
try {
    Main
} catch {
    Write-Log "Erro fatal: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.Exception.StackTrace)" "ERROR" 
    exit 1
}