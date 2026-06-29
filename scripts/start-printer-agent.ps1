[CmdletBinding()]
param(
  [string]$ProjectPath = "C:\securlife-printer-agent"
)

$ErrorActionPreference = "Stop"

$projectFullPath = (Resolve-Path $ProjectPath).Path
$logDir = Join-Path $projectFullPath "tmp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$date = Get-Date -Format "yyyyMMdd"
$stdoutLog = Join-Path $logDir "pm2-start-$date.log"
$stderrLog = Join-Path $logDir "pm2-start-error-$date.log"

Set-Location $projectFullPath

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "$machinePath;$userPath"

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  throw "npm no esta disponible en PATH."
}

& npm.cmd run pm2:start 1>> $stdoutLog 2>> $stderrLog
