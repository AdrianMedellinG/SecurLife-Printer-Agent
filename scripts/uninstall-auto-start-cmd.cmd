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

set "TASK_NAME=SecurLife Printer Agent"
set "TASK_NAME_FULL=\SecurLife Printer Agent"
set "TASK_NOW=SecurLife Printer Agent Start Now"
set "TASK_NOW_FULL=\SecurLife Printer Agent Start Now"

echo ==========================================
echo  SecurLife Printer Agent - Desinstalar
echo ==========================================
echo.
echo Proyecto: %PROJECT_DIR%
echo Puerto: %PORT%
echo.

where schtasks.exe >nul 2>&1
if errorlevel 1 (
  echo schtasks.exe no esta disponible.
  exit /b 1
)

net session >nul 2>&1
if errorlevel 1 (
  echo Este desinstalador debe ejecutarse como Administrador para eliminar la tarea programada.
  echo Clic derecho sobre Desinstalar-Autoarranque.bat y selecciona "Ejecutar como administrador".
  exit /b 1
)

echo Eliminando tarea programada "%TASK_NAME%"...
schtasks.exe /Delete /TN "%TASK_NAME_FULL%" /F >nul 2>&1
if errorlevel 1 (
  schtasks.exe /Delete /TN "%TASK_NAME%" /F >nul 2>&1
)
if errorlevel 1 (
  echo La tarea "%TASK_NAME%" no existia o no se pudo eliminar.
) else (
  echo Tarea "%TASK_NAME%" eliminada.
)

echo Eliminando tarea temporal "%TASK_NOW%" si existe...
schtasks.exe /Delete /TN "%TASK_NOW_FULL%" /F >nul 2>&1
if errorlevel 1 schtasks.exe /Delete /TN "%TASK_NOW%" /F >nul 2>&1

if not exist "%PROJECT_DIR%\package.json" (
  echo No se encontro package.json. Se omitiran comandos PM2.
  goto KILL_PM2
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
  echo npm.cmd no esta disponible. Se omitiran comandos PM2.
  goto KILL_PM2
)

cd /d "%PROJECT_DIR%" || goto KILL_PM2

echo.
echo Deteniendo proceso PM2 del agente...
call npm.cmd run pm2:stop

echo Eliminando proceso PM2 del agente...
call npm.cmd run pm2:delete

echo Guardando estado PM2...
call npm.cmd run pm2:save

:KILL_PM2
echo.
echo Cerrando daemon PM2 local si sigue activo...
for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"%PROJECT_DIR%\node_modules\pm2\lib\Daemon.js"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID taskkill /PID !PID! /T /F >nul 2>&1
)

echo Cerrando proceso que escucha puerto %PORT% si sigue activo...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":%PORT% .*LISTENING"') do (
  taskkill /PID %%P /T /F >nul 2>&1
)

echo.
echo Autoarranque desinstalado.
echo El agente PM2 fue detenido si estaba disponible.
exit /b 0

:USAGE
echo(Uso:
echo(  scripts\uninstall-auto-start-cmd.cmd
echo(  scripts\uninstall-auto-start-cmd.cmd "C:\ruta\al\proyecto"
echo(  scripts\uninstall-auto-start-cmd.cmd "C:\ruta\al\proyecto" 3500
echo(
echo(Elimina la tarea programada de autoarranque y detiene/elimina el proceso PM2.
exit /b 0
