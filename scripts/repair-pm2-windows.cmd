@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="/?" goto USAGE
if /I "%~1"=="-h" goto USAGE
if /I "%~1"=="--help" goto USAGE

set "PROJECT_DIR=%~1"
set "KILL_ALL=0"
if /I "%~1"=="/all" (
  set "PROJECT_DIR=%~dp0.."
  set "KILL_ALL=1"
)
if "%PROJECT_DIR%"=="" set "PROJECT_DIR=%~dp0.."
if /I "%~2"=="/all" set "KILL_ALL=1"

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

set "PM2_DAEMON=%PROJECT_DIR%\node_modules\pm2\lib\Daemon.js"
set "PM2_ANY_DAEMON=\pm2\lib\Daemon.js"
set "FOUND=0"

if "%KILL_ALL%"=="1" (
  echo Buscando cualquier daemon PM2 que pueda bloquear los pipes de Windows...
  echo *\pm2\lib\Daemon.js
) else (
  echo Buscando daemon PM2 de este proyecto...
  echo %PM2_DAEMON%
)
echo.

if "%KILL_ALL%"=="1" (
  set "FIND_PATTERN=%PM2_ANY_DAEMON%"
) else (
  set "FIND_PATTERN=%PM2_DAEMON%"
)

for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"!FIND_PATTERN!"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  set "FOUND=1"
  if defined PID (
    echo Cerrando daemon PM2 PID !PID!...
    taskkill /PID !PID! /F >nul 2>&1
    if errorlevel 1 echo No se pudo cerrar PID !PID!.
  )
)

if "%FOUND%"=="0" (
  echo No se encontraron daemon PM2.
) else (
  ping 127.0.0.1 -n 3 >nul
  echo Daemon PM2 cerrado.
)

echo.
echo Ahora puedes volver a iniciar con:
echo   npm run pm2:start
exit /b 0

:USAGE
echo Uso:
echo   scripts\repair-pm2-windows.cmd
echo   scripts\repair-pm2-windows.cmd "C:\ruta\al\proyecto"
echo   scripts\repair-pm2-windows.cmd "C:\ruta\al\proyecto" /all
echo   scripts\repair-pm2-windows.cmd /all
echo.
echo Cierra daemon PM2. El modo /all cierra cualquier daemon PM2
echo que pueda bloquear los pipes de Windows, pero no cierra procesos Node normales.
exit /b 0
