@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~1"
if "%PROJECT_DIR%"=="" set "PROJECT_DIR=%~dp0.."

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

set "LOG_DIR=%PROJECT_DIR%\tmp"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
set "PM2_CMD=%PROJECT_DIR%\node_modules\.bin\pm2.cmd"

if not exist "%PROJECT_DIR%\package.json" (
  echo [%DATE% %TIME%] No se encontro package.json en "%PROJECT_DIR%".>> "%LOG_DIR%\pm2-start-error.log"
  exit /b 1
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
  echo [%DATE% %TIME%] npm.cmd no esta disponible en PATH.>> "%LOG_DIR%\pm2-start-error.log"
  exit /b 1
)

if not exist "%PM2_CMD%" (
  echo [%DATE% %TIME%] No se encontro PM2 local en "%PM2_CMD%". Ejecuta npm install.>> "%LOG_DIR%\pm2-start-error.log"
  exit /b 1
)

cd /d "%PROJECT_DIR%" || exit /b 1

echo [%DATE% %TIME%] Iniciando SecurLife Printer Agent con PM2...>> "%LOG_DIR%\pm2-start.log"
call :CLEAN_PM2_DAEMONS

call "%PM2_CMD%" startOrReload ecosystem.config.cjs --env production >> "%LOG_DIR%\pm2-start.log" 2>> "%LOG_DIR%\pm2-start-error.log"
if errorlevel 1 exit /b %ERRORLEVEL%

call "%PM2_CMD%" save >> "%LOG_DIR%\pm2-start.log" 2>> "%LOG_DIR%\pm2-start-error.log"
exit /b %ERRORLEVEL%

:CLEAN_PM2_DAEMONS
echo [%DATE% %TIME%] Limpiando daemons PM2 previos...>> "%LOG_DIR%\pm2-start.log"

for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"\pm2\lib\Daemon.js"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID (
    echo [%DATE% %TIME%] Cerrando daemon PM2 PID !PID!...>> "%LOG_DIR%\pm2-start.log"
    taskkill /PID !PID! /T /F >nul 2>&1
  )
)

for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"\@pm2\agent\src\InteractorDaemon.js"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID (
    echo [%DATE% %TIME%] Cerrando interactor PM2 PID !PID!...>> "%LOG_DIR%\pm2-start.log"
    taskkill /PID !PID! /T /F >nul 2>&1
  )
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":3500 .*LISTENING"') do (
  echo [%DATE% %TIME%] Cerrando proceso en puerto 3500 PID %%P...>> "%LOG_DIR%\pm2-start.log"
  taskkill /PID %%P /T /F >nul 2>&1
)

ping 127.0.0.1 -n 3 >nul
exit /b 0
