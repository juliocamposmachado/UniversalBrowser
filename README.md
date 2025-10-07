# 🌐 Universal Browser

**Solução definitiva para sites que fecham inesperadamente**

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fjuliocamposmachado%2FUniversalBrowser)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey.svg)](https://www.microsoft.com/windows)

> 🚀 **Nunca mais perca trabalho por sites que fecham!** Monitora automaticamente sites como iFood, WhatsApp Web e outros, reiniciando-os instantaneamente quando necessário.

## 🌟 **Novidades da Versão Universal**

### ✨ **Recursos Principais**
- **Sistema de Perfis**: Crie perfis personalizados para diferentes sites
- **Detecção Automática de Navegadores**: Suporta Chrome, Edge, Firefox, IE e IE Tab
- **Instalador Automático**: Instala tudo automaticamente no sistema
- **Interface Melhorada**: Comandos intuitivos e interface mais limpa
- **Perfis Pré-configurados**: iFood, WhatsApp Web, Gmail, Office 365 e mais
- **Monitoramento Inteligente**: Cada perfil pode ter configurações únicas
- **Logs Detalhados**: Acompanhe tudo o que acontece
- **Atalhos no Menu Iniciar**: Acesso fácil através do Windows

## 📁 **Estrutura dos Arquivos**

```
C:\UniversalBrowser\
├── UniversalBrowser.ps1         # Script principal universal
├── Install-UniversalBrowser.ps1 # Instalador automático
├── UniversalBrowser.bat         # Interface batch interativa
├── config.json                  # Configurações e perfis
├── README.md                    # Esta documentação
├── Profiles\                    # Perfis personalizados
├── Logs\                        # Logs de execução
└── Backups\                     # Backups de configuração
```

## 🚀 **Instalação Rápida**

### **Método 1: Instalação Automática**
```powershell
# Navegue para a pasta
cd "C:\UniversalBrowser"

# Execute o instalador
.\Install-UniversalBrowser.ps1
```

### **Método 2: Instalação Silenciosa**
```powershell
.\Install-UniversalBrowser.ps1 -Silent
```

### **Desinstalação**
```powershell
.\Install-UniversalBrowser.ps1 -Uninstall
```

## 💻 **Como Usar**

### **Primeira vez - Configure a política de execução:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Opções de Uso:**

#### **1. Interface Interativa (Mais Fácil)**
```batch
# Execute o arquivo batch
C:\UniversalBrowser\UniversalBrowser.bat
```

#### **2. Comandos PowerShell**

**Listar perfis disponíveis:**
```powershell
.\UniversalBrowser.ps1 -ListProfiles
```

**Criar novo perfil:**
```powershell
.\UniversalBrowser.ps1 -CreateProfile
```

**Usar perfil específico:**
```powershell
.\UniversalBrowser.ps1 -ProfileName "iFood"
```

**Abrir URL diretamente:**
```powershell
.\UniversalBrowser.ps1 -Url "https://example.com" -UseChrome
```

#### **3. Perfis Pré-configurados**

**iFood Gestor de Pedidos:**
```powershell
.\UniversalBrowser.ps1 -ProfileName "iFood"
```

**WhatsApp Web:**
```powershell
.\UniversalBrowser.ps1 -ProfileName "WhatsApp Web"
```

**Gmail:**
```powershell
.\UniversalBrowser.ps1 -ProfileName "Gmail"
```

**Office 365:**
```powershell
.\UniversalBrowser.ps1 -ProfileName "Office 365"
```

### **Parâmetros Avançados:**

```powershell
# Usar navegador específico
.\UniversalBrowser.ps1 -ProfileName "iFood" -UseChrome
.\UniversalBrowser.ps1 -ProfileName "iFood" -UseEdge
.\UniversalBrowser.ps1 -ProfileName "iFood" -UseFirefox
.\UniversalBrowser.ps1 -ProfileName "iFood" -UseIE

# Desabilitar monitoramento
.\UniversalBrowser.ps1 -ProfileName "iFood" -NoMonitoring

# Intervalo de monitoramento personalizado
.\UniversalBrowser.ps1 -ProfileName "iFood" -MonitorInterval 60

# Usar navegador personalizado
.\UniversalBrowser.ps1 -Url "https://site.com" -BrowserPath "C:\MeuNavegador\browser.exe"
```

## 🛠️ **Criando Perfis Personalizados**

### **Modo Interativo:**
```powershell
.\UniversalBrowser.ps1 -CreateProfile
```

### **Exemplo de Perfil Personalizado:**
O sistema perguntará:
- **Nome do perfil**: "Meu Site"
- **URL**: "https://meusite.com.br"
- **Intervalo de monitoramento**: "30" segundos
- **Navegador preferido**: "Chrome"
- **Monitoramento**: "Sim"

## 📋 **Perfis Inclusos por Padrão**

| Perfil | URL | Navegador | Monitoramento |
|--------|-----|-----------|---------------|
| **iFood** | gestordepedidos.ifood.com.br | IE Tab | Sim (30s) |
| **WhatsApp Web** | web.whatsapp.com | Chrome | Sim (60s) |
| **Gmail** | mail.google.com | Auto | Não |
| **Office 365** | portal.office.com | Edge | Sim (30s) |

## 🔧 **Recursos Avançados**

### **Sistema de Logs**
- Logs automáticos em `C:\UniversalBrowser\Logs\`
- Um arquivo por dia
- Níveis: INFO, WARN, ERROR
- Busca por perfil específico

**Ver logs em tempo real:**
```powershell
Get-Content "C:\UniversalBrowser\Logs\universal-browser-$(Get-Date -Format 'yyyy-MM-dd').log" -Wait
```

### **Backup e Restauração**
```powershell
# Backup manual da configuração
Copy-Item "C:\UniversalBrowser\config.json" "C:\UniversalBrowser\Backups\config-backup-$(Get-Date -Format 'yyyy-MM-dd').json"
```

### **Atalhos do Sistema**
Após a instalação, você terá:
- **Menu Iniciar**: "Universal Browser" e "Criar Perfil"
- **Área de Trabalho**: "iFood Browser"
- **Associação de arquivos**: Arquivos `.ubprofile`

## ⚠️ **Solução de Problemas**

### **Script não executa**
```powershell
# Verifique a política
Get-ExecutionPolicy

# Configure se necessário  
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Site ainda fecha**
1. Tente navegador específico: `-UseIE` ou `-UseChrome`
2. Desabilite monitoramento: `-NoMonitoring`
3. Verifique bloqueadores de popup
4. Execute como Administrador

### **IE Tab não funciona**
1. Verifique se está instalado: `C:\Users\likel\AppData\Local\IE Tab\18.8.19.1\ietabhelper.exe`
2. Reinstale a extensão IE Tab
3. Use navegador alternativo: `-UseChrome`

### **Reparar instalação**
```powershell
.\Install-UniversalBrowser.ps1 -Repair
```

## 📞 **Suporte e Diagnóstico**

### **Comandos de Diagnóstico:**
```powershell
# Listar navegadores disponíveis
.\UniversalBrowser.ps1 -ListProfiles

# Testar com logs detalhados
.\UniversalBrowser.ps1 -ProfileName "iFood" -NoMonitoring

# Ver configuração atual
Get-Content "C:\UniversalBrowser\config.json" | ConvertFrom-Json
```

### **Logs de Sistema:**
- **Instalação**: `%TEMP%\UniversalBrowser-Install.log`
- **Execução**: `C:\UniversalBrowser\Logs\universal-browser-[data].log`

## 🔄 **Comandos Rápidos de Acesso**

### **Abrir de qualquer lugar:**
```powershell
# iFood
powershell -ExecutionPolicy Bypass -File "C:\UniversalBrowser\UniversalBrowser.ps1" -ProfileName "iFood"

# Criar perfil
powershell -ExecutionPolicy Bypass -File "C:\UniversalBrowser\UniversalBrowser.ps1" -CreateProfile
```

### **Arquivo Batch Personalizado:**
Crie um `meu-site.bat`:
```batch
@echo off
cd /d "C:\UniversalBrowser"
powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ProfileName "MeuSite"
pause
```

## 📊 **Comparação com Versão Anterior**

| Recurso | Versão iFood | Universal Browser |
|---------|--------------|-------------------|
| Sites suportados | Apenas iFood | **Qualquer site** |
| Perfis | 1 fixo | **Ilimitados** |
| Navegadores | 4 básicos | **5 + customizado** |
| Instalação | Manual | **Automática** |
| Interface | Linha de comando | **Batch + PowerShell** |
| Logs | Básicos | **Avançados por perfil** |
| Atalhos | Manuais | **Automáticos** |
| Configuração | Hardcoded | **JSON flexível** |

## 🚀 **Próximas Atualizações**

- [ ] Interface gráfica (GUI) completa
- [ ] Suporte a temas e personalização visual
- [ ] Integração com agendador de tarefas
- [ ] Backup automático na nuvem
- [ ] Perfis sincronizados entre máquinas
- [ ] Suporte a plugins/extensões

---

## 📋 **Resumo de Comandos**

### **Instalação:**
```powershell
.\Install-UniversalBrowser.ps1
```

### **Uso Básico:**
```powershell
# Interface fácil
.\UniversalBrowser.bat

# iFood direto
.\UniversalBrowser.ps1 -ProfileName "iFood"

# Criar perfil
.\UniversalBrowser.ps1 -CreateProfile
```

### **Comandos Úteis:**
```powershell
-ListProfiles          # Lista perfis
-CreateProfile         # Cria perfil 
-ProfileName "Nome"    # Usa perfil específico
-Url "site.com"        # URL direta
-UseChrome             # Força Chrome
-NoMonitoring          # Sem monitoramento
-Repair                # Repara instalação
```

---

*Universal Browser v1.0.0 - Solução completa para sites problemáticos*  
*Evoluído da solução específica para iFood*  
*Localização: C:\UniversalBrowser*