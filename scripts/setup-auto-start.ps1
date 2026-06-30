[CmdletBinding()]
param(
  [string]$ProjectPath = "C:\securlife-printer-agent",
  [string]$TaskName = "SecurLife Printer Agent",
  [ValidateSet("AtLogOn", "AtStartup")]
  [string]$Trigger = "AtLogOn"
)

$ErrorActionPreference = "Stop"

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
  throw "Ejecuta este script en PowerShell como Administrador."
}

$projectFullPath = (Resolve-Path $ProjectPath).Path
$packageJson = Join-Path $projectFullPath "package.json"
$runnerPath = Join-Path $projectFullPath "scripts\start-printer-agent.ps1"
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path $packageJson)) {
  throw "No se encontro package.json en $projectFullPath."
}

if (-not (Test-Path $runnerPath)) {
  throw "No se encontro $runnerPath. Ejecuta primero install-node-and-copy.ps1."
}

Push-Location $projectFullPath
try {
  & npm.cmd run pm2:start
  & npm.cmd run pm2:save
} finally {
  Pop-Location
}

$argumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`" -ProjectPath `"$projectFullPath`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argumentList -WorkingDirectory $projectFullPath

$scheduledTriggers = @(
  New-ScheduledTaskTrigger -AtLogOn -User $currentUser
)

if ($Trigger -eq "AtStartup") {
  $scheduledTriggers += New-ScheduledTaskTrigger -AtStartup
}

$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Days 3650) `
  -MultipleInstances IgnoreNew `
  -RestartCount 3 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -StartWhenAvailable

$task = New-ScheduledTask -Action $action -Trigger $scheduledTriggers -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

Write-Host "Tarea programada instalada: $TaskName"
Write-Host "Proyecto: $projectFullPath"
Write-Host "Trigger: $Trigger"
Write-Host "Logs: $projectFullPath\tmp"
Write-Host "Comandos PM2: npm run pm2:status, npm run pm2:logs, npm run pm2:restart"
