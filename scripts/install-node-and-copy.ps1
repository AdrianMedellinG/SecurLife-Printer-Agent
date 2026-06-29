[CmdletBinding()]
param(
  [string]$TargetPath = "C:\koders-printer-agent",
  [switch]$SkipNodeInstall,
  [switch]$SkipNpmInstall
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Refresh-Path {
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machinePath;$userPath"
}

function Test-NodeAndNpm {
  Refresh-Path
  return [bool](Get-Command node -ErrorAction SilentlyContinue) -and [bool](Get-Command npm -ErrorAction SilentlyContinue)
}

function Install-NodeLts {
  Write-Host "Instalando Node.js LTS..."

  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    & winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
    Refresh-Path
    if (Test-NodeAndNpm) {
      return
    }
  }

  Write-Host "winget no instalo Node.js. Descargando instalador MSI desde nodejs.org..."
  $releases = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json"
  $latestLts = $releases | Where-Object { $_.lts -ne $false } | Select-Object -First 1
  if (-not $latestLts) {
    throw "No se pudo detectar la version LTS de Node.js."
  }

  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "x64" }
  $version = $latestLts.version
  $msiName = "node-$version-$arch.msi"
  $msiPath = Join-Path $env:TEMP $msiName
  $downloadUrl = "https://nodejs.org/dist/$version/$msiName"

  Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath
  $msiArguments = "/i `"$msiPath`" /qn /norestart"
  $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArguments -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    throw "El instalador de Node.js fallo con codigo $($process.ExitCode)."
  }

  Refresh-Path
  if (-not (Test-NodeAndNpm)) {
    throw "Node.js se instalo, pero node/npm no quedaron disponibles en PATH. Reinicia PowerShell y vuelve a intentar."
  }
}

if (-not (Test-Administrator)) {
  throw "Ejecuta este script en PowerShell como Administrador."
}

$sourcePath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
$targetRoot = [System.IO.Path]::GetPathRoot($targetFullPath)

if ($targetFullPath.TrimEnd("\") -ieq $sourcePath.TrimEnd("\")) {
  throw "La carpeta destino no puede ser la misma carpeta origen."
}

if ($targetFullPath.TrimEnd("\") -ieq $targetRoot.TrimEnd("\")) {
  throw "La carpeta destino no puede ser la raiz de la unidad. Usa una carpeta como C:\koders-printer-agent."
}

$sourcePrefix = $sourcePath.TrimEnd("\") + "\"
$targetPrefix = $targetFullPath.TrimEnd("\") + "\"
if ($targetPrefix.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
  throw "La carpeta destino no puede estar dentro de la carpeta origen."
}

if ($sourcePrefix.StartsWith($targetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
  throw "La carpeta destino no puede ser una carpeta padre de la carpeta origen."
}

if (-not $SkipNodeInstall -and -not (Test-NodeAndNpm)) {
  Install-NodeLts
} else {
  Write-Host "Node.js/npm ya estan disponibles."
}

Write-Host "Copiando proyecto a $targetFullPath..."
New-Item -ItemType Directory -Force -Path $targetFullPath | Out-Null

$robocopyArgs = @(
  $sourcePath,
  $targetFullPath,
  "/MIR",
  "/XD", "node_modules", ".git", "tmp",
  "/R:2",
  "/W:2",
  "/NFL",
  "/NDL",
  "/NP"
)

& robocopy @robocopyArgs | Out-Host
$robocopyExitCode = $LASTEXITCODE
if ($robocopyExitCode -gt 7) {
  throw "robocopy fallo con codigo $robocopyExitCode."
}

if (-not $SkipNpmInstall) {
  Write-Host "Instalando dependencias en $targetFullPath..."
  Push-Location $targetFullPath
  try {
    if (Test-Path "package-lock.json") {
      & npm.cmd ci --omit=dev
    } else {
      & npm.cmd install --omit=dev
    }
  } finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "Listo. Proyecto instalado en $targetFullPath"
Write-Host "PM2 quedo instalado como dependencia local del proyecto."
Write-Host "Siguiente paso: ejecuta scripts\setup-auto-start.cmd como Administrador para activar el inicio automatico con PM2."
