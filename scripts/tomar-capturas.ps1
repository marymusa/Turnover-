# Toma las ocho capturas de la ficha de Play y las deja en store/es-ES/screenshots/.
#
# Necesita el APK de capturas ya instalado:
#
#     flutter build apk --debug -t scripts/capture_main.dart
#     adb install -r build/app/outputs/flutter-apk/app-debug.apk
#     powershell -File scripts/tomar-capturas.ps1 -Serial <serie>
#
# Va en PowerShell y no en Bash a proposito: desde Git Bash las rutas /sdcard/
# se traducen a rutas de Windows y adb escribe donde no toca.

param(
    [string]$Serial = '',
    [string]$OutDir = 'store/es-ES/screenshots'
)

# adb escribe por stderr cosas que no son errores (el resumen de `pull`). Con
# ErrorActionPreference a Stop, PowerShell las convierte en excepciones y aborta
# a mitad. Cada captura se valida a mano en cuanto se trae, que para esto es mas
# fiable que fiarse del canal de error.
$ErrorActionPreference = 'Continue'

# El orden es el de la ficha, y el indice de cada una es su posicion en la lista
# de `scripts/capture_main.dart`: si se cambia una, hay que cambiar la otra.
$shots = @(
    '01-antes-de-empezar',
    '02-turno-corriendo',
    '03-aviso-previo',
    '04-tiempo-extra-consumiendose',
    '05-overtime',
    '06-pausado',
    '07-nombres',
    '08-ajustes'
)

# La presentacion del escudo dura dos segundos y pico y se repite en cada
# arranque, asi que hay que dejarla terminar o la captura sale a medio dibujar.
# El margen es generoso a proposito: una captura mala no se nota hasta que se
# mira, y repetir la tanda cuesta mas que esperar.
$revealWait = 5

$adb = if ($Serial) { @('-s', $Serial) } else { @() }
$package = 'com.ares.bloodbowl.turnover'
$remoteShot = '/sdcard/turnover-capture.png'

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}

for ($i = 0; $i -lt $shots.Count; $i++) {
    $shot = $shots[$i]
    $target = Join-Path $OutDir "$shot.png"
    Write-Host "[$($i + 1)/$($shots.Count)] $shot"

    # La primera arranca la aplicacion; las siguientes se piden con un toque en
    # la banda del borde izquierdo, que es lo que pasa a la captura siguiente.
    if ($i -eq 0) {
        & adb @adb shell am force-stop $package
        & adb @adb shell am start -n "$package/.MainActivity" | Out-Null
    } else {
        & adb @adb shell input tap 14 1200
    }
    Start-Sleep -Seconds $revealWait

    & adb @adb shell screencap -p $remoteShot
    & adb @adb pull -a $remoteShot $target 2>&1 | Out-Null
    & adb @adb shell rm -f $remoteShot

    if (-not (Test-Path $target)) {
        throw "No se ha traido la captura $shot"
    }
    $size = (Get-Item $target).Length
    if ($size -lt 10000) {
        throw "La captura $shot ha salido vacia ($size bytes)"
    }
}

& adb @adb shell am force-stop $package

# Dos capturas iguales quieren decir que el estado no se sembro y que la tanda
# no vale: es el fallo que ya se colo una vez, y en miniatura no se ve.
$hashes = @{}
foreach ($shot in $shots) {
    $target = Join-Path $OutDir "$shot.png"
    $hash = (Get-FileHash $target -Algorithm MD5).Hash
    if ($hashes.ContainsKey($hash)) {
        throw "$shot ha salido igual que $($hashes[$hash]): el estado no se ha sembrado"
    }
    $hashes[$hash] = $shot
}

Write-Host ''
Write-Host "Listo: $($shots.Count) capturas en $OutDir"
Write-Host 'Repasalas antes de subirlas: el reloj de cada una tiene que ser el que dice su nombre.'
