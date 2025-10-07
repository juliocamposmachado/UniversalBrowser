@echo off
title Universal Browser
echo.
echo ===============================================
echo        Universal Browser v1.0.0
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
    cd /d "C:\UniversalBrowser"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ProfileName "iFood"
) else if "%choice%"=="2" (
    cd /d "C:\UniversalBrowser"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -CreateProfile
) else if "%choice%"=="3" (
    cd /d "C:\UniversalBrowser"
    powershell.exe -ExecutionPolicy Bypass -File "UniversalBrowser.ps1" -ListProfiles
    pause
) else if "%choice%"=="4" (
    cd /d "C:\UniversalBrowser"
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
