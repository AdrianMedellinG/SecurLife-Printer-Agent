@echo off
setlocal

REM === RUTA DEL PROYECTO ===
set "PROJECT_DIR=%~dp0"

cd /d "%PROJECT_DIR%"

:MENU
cls
echo ==================================
echo      SECURLIFE PRINTER AGENT
echo ==================================
echo 1) Iniciar agente con PM2
echo 2) Ver estado PM2
echo 3) Ver logs PM2
echo 4) Reiniciar agente PM2
echo 5) Detener agente PM2
echo 6) Listar impresoras
echo 7) Imprimir etiqueta de prueba
echo 8) Reparar PM2 EPERM
echo 0) Salir
echo ==================================
set /p opt=Elige una opcion: 

if "%opt%"=="0" goto END

if "%opt%"=="1" (
  call npm run pm2:start
  call npm run pm2:save
  pause
  goto MENU
)

if "%opt%"=="2" (
  call npm run pm2:status
  pause
  goto MENU
)

if "%opt%"=="3" (
  call npm run pm2:logs
  pause
  goto MENU
)

if "%opt%"=="4" (
  call npm run pm2:restart
  pause
  goto MENU
)

if "%opt%"=="5" (
  call npm run pm2:stop
  pause
  goto MENU
)

if "%opt%"=="6" (
  call npm run list-printers
  pause
  goto MENU
)

if "%opt%"=="7" (
  call npm run test-label
  pause
  goto MENU
)

if "%opt%"=="8" (
  call scripts\repair-pm2-windows.cmd "%PROJECT_DIR%" /all
  pause
  goto MENU
)

echo Opcion invalida.
pause
goto MENU

:END
endlocal
