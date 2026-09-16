# Instala y arranca la aplicacion en el emulador.
#
# Antes de nada hace falta un emulador encendido: .\scripts\run-emulator.ps1
#
# La compilacion incremental de Kotlin va desactivada en
# android/gradle.properties: con ella puesta el build falla siempre con
# "Could not close incremental caches".

param(
  [string]$Device = '',
  [switch]$Release,
  [switch]$Clean
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)


if (-not $Device) {
  $line = adb devices | Select-String -Pattern '^(emulator-\d+)\s+device$'
  if (-not $line) {
    Write-Host "No hay ningun emulador encendido. Arrancar primero:" -ForegroundColor Yellow
    Write-Host "  .\scripts\run-emulator.ps1"
    exit 1
  }
  $Device = $line.Matches[0].Groups[1].Value
}

if ($Clean) {
  # Los demonios de Gradle y Kotlin dejan la carpeta build bloqueada, asi que
  # hay que pararlos antes de poder borrarla.
  Write-Host "Parando demonios y limpiando..."
  Get-Process -Name java,dart,dartvm -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  if (Test-Path build) { Remove-Item build -Recurse -Force -ErrorAction SilentlyContinue }
}

$mode = if ($Release) { '--release' } else { '--debug' }
Write-Host "flutter run -d $Device $mode"
flutter run -d $Device $mode
