# Arranca el emulador de Android y espera a que termine de encender.
#
# El identificador sale de `flutter emulators`. Si algun dia hay otro aparato,
# se pasa como argumento: .\scripts\run-emulator.ps1 -Emulator Pixel_9

param([string]$Emulator = 'Pixel_8')

$ErrorActionPreference = 'Stop'

$running = (adb devices | Select-String -Pattern '^emulator-\d+\s+device$')
if ($running) {
  Write-Host "Ya hay un emulador encendido:"
  adb devices | Select-String -Pattern '^emulator-'
  exit 0
}

Write-Host "Arrancando $Emulator..."
flutter emulators --launch $Emulator

# `flutter emulators --launch` vuelve en cuanto lanza el proceso, no cuando el
# aparato esta listo, asi que hay que esperar al arranque a mano.
Write-Host "Esperando al arranque..."
adb wait-for-device
do {
  Start-Sleep -Seconds 3
  $booted = (adb shell getprop sys.boot_completed 2>$null).Trim()
} while ($booted -ne '1')

Write-Host "Emulador listo:"
adb devices | Select-String -Pattern '^emulator-'
