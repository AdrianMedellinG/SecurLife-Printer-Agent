@echo off
if /I not "%~1"=="--inner" (
  cmd.exe /k ""%~f0" --inner %*"
  exit /b %ERRORLEVEL%
)
shift

setlocal EnableExtensions EnableDelayedExpansion

set "REPO_ZIP_MAIN=https://codeload.github.com/AdrianMedellinG/SecurLife-Printer-Agent/zip/refs/heads/main"
set "REPO_ZIP_MASTER=https://codeload.github.com/AdrianMedellinG/SecurLife-Printer-Agent/zip/refs/heads/master"
set "TARGET_DIR=C:\securlife-printer-agent"
set "NODE_VERSION=22.22.3"
set "NODE_ARCH=x64"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "NODE_ARCH=arm64"
set "NODE_MSI=node-v%NODE_VERSION%-%NODE_ARCH%.msi"
set "NODE_URL=https://nodejs.org/download/release/v%NODE_VERSION%/%NODE_MSI%"
set "WORK_DIR=%TEMP%\securlife-printer-agent-install"
set "ZIP_PATH=%WORK_DIR%\repo.zip"
set "LOG_PATH=%TEMP%\securlife-printer-agent-install.log"

echo ==========================================
echo  SecurLife Printer Agent - Instalador CMD
echo ==========================================
echo.
echo Log: %LOG_PATH%
echo.

echo ==== SecurLife Printer Agent installer ==== > "%LOG_PATH%"
echo Inicio: %DATE% %TIME% >> "%LOG_PATH%"

net session >nul 2>&1
if errorlevel 1 (
  echo Ejecuta este .bat desde CMD como Administrador.
  echo Es necesario para instalar Node.js con MSI.
  pause
  exit /b 1
)

where curl.exe >nul 2>&1
if errorlevel 1 (
  echo No se encontro curl.exe. Este instalador requiere Windows 10/11 con curl.
  pause
  exit /b 1
)

where tar.exe >nul 2>&1
if errorlevel 1 (
  echo No se encontro tar.exe. Este instalador requiere Windows 10/11 con tar.
  pause
  exit /b 1
)

if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
mkdir "%WORK_DIR%" >nul 2>&1

echo.
echo [0/7] Revisando y deteniendo procesos PM2 previos...
echo [0/7] Revisando y deteniendo procesos PM2 previos... >> "%LOG_PATH%"
call :CLEAN_PM2_DAEMONS

echo.
echo [1/7] Instalando Node.js %NODE_VERSION% LTS con npm...
echo [1/7] Revisando Node.js... >> "%LOG_PATH%"
set "CURRENT_NODE="
set "NODE_MAJOR="
set "SKIP_NODE_INSTALL=0"
for /f "delims=" %%V in ('node.exe -v 2^>nul') do set "CURRENT_NODE=%%V"

if defined CURRENT_NODE (
  echo Node detectado: !CURRENT_NODE!
  echo Node detectado: !CURRENT_NODE! >> "%LOG_PATH%"
  set "NODE_MAJOR=!CURRENT_NODE:~1,2!"
  if "!NODE_MAJOR!"=="22" set "SKIP_NODE_INSTALL=1"
  if "!NODE_MAJOR!"=="23" set "SKIP_NODE_INSTALL=1"
  if "!NODE_MAJOR!"=="24" set "SKIP_NODE_INSTALL=1"
) else (
  echo Node no detectado. Se instalara Node.js %NODE_VERSION%.
  echo Node no detectado. Se instalara Node.js %NODE_VERSION%. >> "%LOG_PATH%"
)

if "!SKIP_NODE_INSTALL!"=="1" (
  echo Node.js !CURRENT_NODE! ya esta instalado. Se omite la descarga de Node.js %NODE_VERSION%.
  echo Node.js !CURRENT_NODE! ya esta instalado. Se omite la descarga de Node.js %NODE_VERSION%. >> "%LOG_PATH%"
  echo Continuando con el siguiente paso...
  echo Continuando con el siguiente paso... >> "%LOG_PATH%"
) else (
  echo Descargando %NODE_URL%
  echo Descargando %NODE_URL% >> "%LOG_PATH%"
  curl.exe -L --fail -o "%WORK_DIR%\%NODE_MSI%" "%NODE_URL%"
  if errorlevel 1 goto FAIL

  echo Instalando Node.js. Esto puede tardar unos minutos...
  echo Instalando Node.js desde MSI... >> "%LOG_PATH%"
  msiexec.exe /i "%WORK_DIR%\%NODE_MSI%" /qn /norestart
  if errorlevel 1 goto FAIL
)

set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"

where node.exe >nul 2>&1
if errorlevel 1 (
  echo Node.js no quedo disponible en PATH.
  echo Reinicia CMD y vuelve a intentar.
  goto FAIL
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
  echo npm no quedo disponible en PATH.
  echo Reinicia CMD y vuelve a intentar.
  goto FAIL
)

echo.
echo Versiones instaladas:
node.exe -v
call npm.cmd -v
echo Node despues de validacion: >> "%LOG_PATH%"
node.exe -v >> "%LOG_PATH%" 2>&1
echo npm despues de validacion: >> "%LOG_PATH%"
call npm.cmd -v >> "%LOG_PATH%" 2>&1

echo.
echo [2/7] Descargando repositorio de GitHub...
curl.exe -L --fail -o "%ZIP_PATH%" "%REPO_ZIP_MAIN%"
if errorlevel 1 (
  echo No se pudo descargar branch main. Intentando master...
  curl.exe -L --fail -o "%ZIP_PATH%" "%REPO_ZIP_MASTER%"
  if errorlevel 1 goto FAIL
)

echo.
echo [3/7] Extrayendo repositorio...
tar.exe -xf "%ZIP_PATH%" -C "%WORK_DIR%"
if errorlevel 1 goto FAIL

set "EXTRACTED_DIR="
for /d %%D in ("%WORK_DIR%\SecurLife-Printer-Agent-*") do set "EXTRACTED_DIR=%%~fD"

if "%EXTRACTED_DIR%"=="" (
  echo No se encontro la carpeta extraida del repositorio.
  goto FAIL
)

echo.
echo [4/7] Copiando proyecto a %TARGET_DIR%...
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%" >nul 2>&1
robocopy "%EXTRACTED_DIR%" "%TARGET_DIR%" /E /XD ".git" "node_modules" "tmp" /R:2 /W:2 /NFL /NDL /NP
set "ROBOCOPY_EXIT=%ERRORLEVEL%"
if %ROBOCOPY_EXIT% GTR 7 (
  echo robocopy fallo con codigo %ROBOCOPY_EXIT%.
  goto FAIL
)

if not exist "%TARGET_DIR%\scripts" mkdir "%TARGET_DIR%\scripts" >nul 2>&1
if exist "%~dp0scripts\configure-printer.js" copy /Y "%~dp0scripts\configure-printer.js" "%TARGET_DIR%\scripts\configure-printer.js" >nul
if exist "%~dp0scripts\start-printer-agent.cmd" copy /Y "%~dp0scripts\start-printer-agent.cmd" "%TARGET_DIR%\scripts\start-printer-agent.cmd" >nul
if exist "%~dp0scripts\setup-auto-start-cmd.cmd" copy /Y "%~dp0scripts\setup-auto-start-cmd.cmd" "%TARGET_DIR%\scripts\setup-auto-start-cmd.cmd" >nul
if exist "%~dp0scripts\reset-pm2-eperm.cmd" copy /Y "%~dp0scripts\reset-pm2-eperm.cmd" "%TARGET_DIR%\scripts\reset-pm2-eperm.cmd" >nul
if exist "%~dp0scripts\repair-pm2-windows.cmd" copy /Y "%~dp0scripts\repair-pm2-windows.cmd" "%TARGET_DIR%\scripts\repair-pm2-windows.cmd" >nul
if exist "%~dp0Impresora.bat" copy /Y "%~dp0Impresora.bat" "%TARGET_DIR%\Impresora.bat" >nul

if not exist "%TARGET_DIR%\scripts\start-printer-agent.cmd" (
  echo Creando scripts\start-printer-agent.cmd...
  (
    echo @echo off
    echo setlocal EnableExtensions
    echo set "PROJECT_DIR=%%~1"
    echo if "%%PROJECT_DIR%%"=="" set "PROJECT_DIR=%%~dp0.."
    echo for %%%%I in ^("%%PROJECT_DIR%%"^) do set "PROJECT_DIR=%%%%~fI"
    echo set "PATH=%%ProgramFiles%%\nodejs;%%APPDATA%%\npm;%%PATH%%"
    echo cd /d "%%PROJECT_DIR%%" ^|^| exit /b 1
    echo call npm.cmd run pm2:start
    echo if errorlevel 1 exit /b %%ERRORLEVEL%%
    echo call npm.cmd run pm2:save
    echo exit /b %%ERRORLEVEL%%
  ) > "%TARGET_DIR%\scripts\start-printer-agent.cmd"
)

cd /d "%TARGET_DIR%" || goto FAIL

echo.
echo [5/7] Instalando node_modules y PM2 local...
set "NEEDS_NPM_INSTALL=1"
if exist "node_modules\pm2" if exist "node_modules\pdf-to-printer" if exist "node_modules\sharp" set "NEEDS_NPM_INSTALL=0"

if "%NEEDS_NPM_INSTALL%"=="0" (
  echo node_modules ya existe con las dependencias principales. Se omite reinstalacion.
  echo node_modules ya existe con las dependencias principales. Se omite reinstalacion. >> "%LOG_PATH%"
  goto NPM_DONE
)

if not exist package-lock.json goto NPM_INSTALL

echo Instalando dependencias con npm ci...
echo Instalando dependencias con npm ci... >> "%LOG_PATH%"
call npm.cmd ci --omit=dev
if errorlevel 1 goto FAIL
goto NPM_DONE

:NPM_INSTALL
echo Instalando dependencias con npm install...
echo Instalando dependencias con npm install... >> "%LOG_PATH%"
call npm.cmd install --omit=dev
if errorlevel 1 goto FAIL

:NPM_DONE

if not exist ".env" (
  echo Copiando .env.example a .env...
  copy ".env.example" ".env" >nul
) else (
  echo Ya existe .env. Se conservara y solo se actualizara PRINTER_NAME.
)

echo.
echo PM2 instalado localmente:
call npx.cmd pm2 -v
if errorlevel 1 goto FAIL

echo.
echo [6/7] Detectando impresoras instaladas...
call npm.cmd run list-printers
if errorlevel 1 goto FAIL

if exist "scripts\configure-printer.js" (
  call node.exe scripts\configure-printer.js
  if errorlevel 1 goto FAIL
) else (
  echo.
  echo El repositorio descargado no incluye scripts\configure-printer.js.
  echo Copia exactamente el nombre de la impresora desde la lista anterior.
  set "SELECTED_PRINTER="
  set /p SELECTED_PRINTER=Nombre exacto de la impresora para PRINTER_NAME: 
  if not defined SELECTED_PRINTER goto FAIL
  node.exe -e "const fs=require('fs');const p='.env';const k='PRINTER_NAME';const v=process.env.SELECTED_PRINTER||'';let c=fs.existsSync(p)?fs.readFileSync(p,'utf8'):fs.readFileSync('.env.example','utf8');const lines=c.split(/\r?\n/);let found=false;for(let i=0;i<lines.length;i++){if(lines[i].startsWith(k+'=')){lines[i]=k+'='+v;found=true;}}if(found===false)lines.push(k+'='+v);fs.writeFileSync(p,lines.join('\r\n'));console.log('PRINTER_NAME actualizado en .env: '+v);"
  if errorlevel 1 goto FAIL
)

echo.
echo [7/7] Iniciando microservicio con PM2...
echo Limpiando daemons PM2 previos para evitar EPERM en Windows...
echo Limpiando daemons PM2 previos... >> "%LOG_PATH%"
call :CLEAN_PM2_DAEMONS
call :START_AGENT_WITH_TASK
if errorlevel 1 (
  echo.
  echo PM2 fallo al iniciar. Si ves EPERM con //./pipe/rpc.sock:
  echo   1. Ejecuta: scripts\reset-pm2-eperm.cmd
  echo   2. Cierra este CMD de Administrador.
  echo   3. Abre CMD normal y ejecuta: Impresora.bat
  goto FAIL
)

echo.
echo Instalacion completada.
echo El microservicio debe estar activo en:
echo   http://localhost:3500
echo.

set "AUTO_START="
set /p AUTO_START=Quieres activar el auto inicio con CMD al iniciar sesion? (S/N): 
if /I "%AUTO_START%"=="S" (
  if exist scripts\setup-auto-start-cmd.cmd (
    call scripts\setup-auto-start-cmd.cmd "%TARGET_DIR%"
    if errorlevel 1 goto FAIL
  ) else (
    set "AUTO_TASK_NAME=SecurLife Printer Agent"
    set "AUTO_TASK_COMMAND=%ComSpec% /d /c ""%TARGET_DIR%\scripts\start-printer-agent.cmd" "%TARGET_DIR%"""
    schtasks.exe /Create /TN "!AUTO_TASK_NAME!" /SC ONLOGON /TR "!AUTO_TASK_COMMAND!" /F
    if errorlevel 1 goto FAIL
    schtasks.exe /Run /TN "!AUTO_TASK_NAME!"
    if errorlevel 1 goto FAIL
  )
)

echo.
echo Listo.
pause
exit /b 0

:CLEAN_PM2_DAEMONS
for /f "usebackq delims=" %%L in (`wmic process where "name='node.exe'" get CommandLine^,ProcessId 2^>nul ^| findstr /i /l /c:"\pm2\lib\Daemon.js"`) do (
  set "LINE=%%L"
  set "PID="
  for %%A in (!LINE!) do set "PID_RAW=%%A"
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID (
    echo Cerrando daemon PM2 PID !PID!...
    echo Cerrando daemon PM2 PID !PID!... >> "%LOG_PATH%"
    taskkill /PID !PID! /T /F >nul 2>&1
  )
)

for /f "tokens=2 delims==" %%P in ('wmic process where "name='node.exe' and CommandLine is null" get ProcessId /value 2^>nul ^| find "="') do (
  set "PID_RAW=%%P"
  set "PID="
  set /a "PID=!PID_RAW!" >nul 2>&1
  if defined PID (
    echo Cerrando node.exe sin CommandLine PID !PID!...
    echo Cerrando node.exe sin CommandLine PID !PID!... >> "%LOG_PATH%"
    taskkill /PID !PID! /T /F >nul 2>&1
  )
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":3500 .*LISTENING"') do (
  echo Cerrando proceso que escucha puerto 3500 PID %%P...
  echo Cerrando proceso que escucha puerto 3500 PID %%P... >> "%LOG_PATH%"
  taskkill /PID %%P /T /F >nul 2>&1
)

ping 127.0.0.1 -n 3 >nul
exit /b 0

:START_AGENT_WITH_TASK
set "TASK_NOW=SecurLife Printer Agent Start Now"
set "TASK_COMMAND=%ComSpec% /d /c ""%TARGET_DIR%\scripts\start-printer-agent.cmd" "%TARGET_DIR%"""

schtasks.exe /Create /TN "%TASK_NOW%" /SC ONLOGON /TR "%TASK_COMMAND%" /F >nul
if errorlevel 1 exit /b 1

schtasks.exe /Run /TN "%TASK_NOW%" >nul
if errorlevel 1 exit /b 1

echo Esperando respuesta de http://localhost:3500/health ...
for /L %%I in (1,1,30) do (
  curl.exe -fs "http://localhost:3500/health" >nul 2>&1
  if not errorlevel 1 (
    schtasks.exe /Delete /TN "%TASK_NOW%" /F >nul 2>&1
    echo Microservicio activo.
    exit /b 0
  )
  ping 127.0.0.1 -n 2 >nul
)

schtasks.exe /Delete /TN "%TASK_NOW%" /F >nul 2>&1
echo El microservicio no respondio en /health.
exit /b 1

:FAIL
echo.
echo Instalacion detenida por error.
echo Revisa los mensajes anteriores.
echo Error: instalacion detenida en %DATE% %TIME% >> "%LOG_PATH%"
echo Log: %LOG_PATH%
pause
exit /b 1
