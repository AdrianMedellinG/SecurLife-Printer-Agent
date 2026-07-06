@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="/?" goto USAGE
if /I "%~1"=="-h" goto USAGE
if /I "%~1"=="--help" goto USAGE

set "PROJECT_DIR=%~1"
if "%PROJECT_DIR%"=="" set "PROJECT_DIR=%~dp0.."
set "PORT=%~2"
if "%PORT%"=="" set "PORT=3500"

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

net session >nul 2>&1
if errorlevel 1 (
  echo Ejecuta este script desde CMD como Administrador.
  echo.
  echo Despues de la limpieza, cierra el CMD de Administrador y arranca
  echo el agente desde un CMD normal o con Impresora.bat.
  exit /b 1
)

echo Limpiando procesos que pueden bloquear PM2 en Windows...
echo Proyecto: %PROJECT_DIR%
echo Puerto: %PORT%
echo.

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":%PORT% .*LISTENING"') do (
  call :KILL_WITH_PARENT %%P
)

for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"\pm2\lib\Daemon.js"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID (
    echo Cerrando daemon PM2 PID !PID!...
    taskkill /PID !PID! /T /F >nul 2>&1
  )
)

echo.
echo Limpieza terminada.
echo Cierra este CMD de Administrador y arranca el agente desde CMD normal:
echo   Impresora.bat
echo.
echo En el menu, usa:
echo   1) Iniciar agente con PM2
exit /b 0

:KILL_WITH_PARENT
set "PID=%~1"
set "PARENT_PID="

for /f "tokens=2 delims==" %%A in ('wmic process where "ProcessId=%PID%" get ParentProcessId /value 2^>nul ^| find "="') do (
  set "PARENT_RAW=%%A"
  set /a "PARENT_PID=!PARENT_RAW!" >nul 2>&1
)

if defined PARENT_PID (
  if not "%PARENT_PID%"=="0" (
    echo Cerrando arbol padre PID !PARENT_PID! del proceso que escucha el puerto %PORT%...
    taskkill /PID !PARENT_PID! /T /F >nul 2>&1
  )
)

echo Cerrando proceso PID %PID% que escucha el puerto %PORT%...
taskkill /PID %PID% /T /F >nul 2>&1
exit /b 0

:USAGE
echo Uso:
echo   scripts\reset-pm2-eperm.cmd
echo   scripts\reset-pm2-eperm.cmd "C:\ruta\al\proyecto" 3500
echo.
echo Ejecuta desde CMD como Administrador para cerrar procesos PM2 elevados
echo que bloquean //./pipe/rpc.sock o //./pipe/interactor.sock.
exit /b 0
