@echo off
setlocal EnableExtensions

set "PROJECT_DIR=%~1"
if "%PROJECT_DIR%"=="" set "PROJECT_DIR=%~dp0.."

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

set "LOG_DIR=%PROJECT_DIR%\tmp"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"

if not exist "%PROJECT_DIR%\package.json" (
  echo [%DATE% %TIME%] No se encontro package.json en "%PROJECT_DIR%".>> "%LOG_DIR%\pm2-start-error.log"
  exit /b 1
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
  echo [%DATE% %TIME%] npm.cmd no esta disponible en PATH.>> "%LOG_DIR%\pm2-start-error.log"
  exit /b 1
)

cd /d "%PROJECT_DIR%" || exit /b 1

echo [%DATE% %TIME%] Iniciando SecurLife Printer Agent con PM2...>> "%LOG_DIR%\pm2-start.log"
call npm.cmd run pm2:start >> "%LOG_DIR%\pm2-start.log" 2>> "%LOG_DIR%\pm2-start-error.log"
exit /b %ERRORLEVEL%
