@echo off
setlocal EnableExtensions

set "PROJECT_DIR=%~dp0"
set "UNINSTALLER=%PROJECT_DIR%scripts\uninstall-auto-start-cmd.cmd"

net session >nul 2>&1
if errorlevel 1 (
  echo Solicitando permisos de Administrador...
  set "ELEVATE_VBS=%TEMP%\securlife-uninstall-autostart-elevate.vbs"
  (
    echo Set shell = CreateObject^("Shell.Application"^)
    echo shell.ShellExecute "cmd.exe", "/c ""%UNINSTALLER%"" ""%PROJECT_DIR%"" ^& echo. ^& echo Presiona una tecla para cerrar esta ventana... ^& pause ^>nul", "", "runas", 1
  ) > "%ELEVATE_VBS%"
  wscript.exe "%ELEVATE_VBS%"
  del "%ELEVATE_VBS%" >nul 2>&1
  exit /b 0
)

call "%UNINSTALLER%" "%PROJECT_DIR%"
echo.
echo Presiona una tecla para cerrar esta ventana...
pause >nul
