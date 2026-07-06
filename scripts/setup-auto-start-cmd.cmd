@echo off
setlocal EnableExtensions

if "%~1"=="/?" goto USAGE
if /I "%~1"=="-h" goto USAGE
if /I "%~1"=="--help" goto USAGE

set "PROJECT_DIR=%~1"
if "%PROJECT_DIR%"=="" set "PROJECT_DIR=%~dp0.."

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

set "TASK_NAME=SecurLife Printer Agent"
set "RUNNER_PATH=%PROJECT_DIR%\scripts\start-printer-agent.cmd"
set "TASK_COMMAND=%ComSpec% /d /c ""%RUNNER_PATH%"""

net session >nul 2>&1
if errorlevel 1 (
  echo Ejecuta este script desde CMD como Administrador.
  exit /b 1
)

if not exist "%PROJECT_DIR%\package.json" (
  echo No se encontro package.json en "%PROJECT_DIR%".
  exit /b 1
)

if not exist "%RUNNER_PATH%" (
  echo No se encontro "%RUNNER_PATH%".
  exit /b 1
)

where schtasks.exe >nul 2>&1
if errorlevel 1 (
  echo schtasks.exe no esta disponible.
  exit /b 1
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
  echo npm.cmd no esta disponible en PATH.
  exit /b 1
)

echo Registrando tarea programada "%TASK_NAME%"...
schtasks.exe /Create /TN "%TASK_NAME%" /SC ONLOGON /TR "%TASK_COMMAND%" /F
if errorlevel 1 exit /b 1

echo Iniciando agente ahora...
call "%RUNNER_PATH%" "%PROJECT_DIR%"
if errorlevel 1 exit /b 1

cd /d "%PROJECT_DIR%" || exit /b 1
call npm.cmd run pm2:save

echo.
echo Tarea programada instalada: %TASK_NAME%
echo Proyecto: %PROJECT_DIR%
echo Trigger: al iniciar sesion despues de reiniciar Windows
echo Logs: %PROJECT_DIR%\tmp
echo.
echo Para revisar el proceso:
echo   npm run pm2:status
exit /b 0

:USAGE
echo Uso:
echo   scripts\setup-auto-start-cmd.cmd
echo   scripts\setup-auto-start-cmd.cmd "C:\ruta\al\proyecto"
echo.
echo Registra una tarea programada de Windows que inicia PM2 con este proyecto
echo usando cmd.exe al iniciar sesion el usuario.
exit /b 0
