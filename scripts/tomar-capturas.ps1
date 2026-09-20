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

# Las ocho de la ficha. `File` manda el orden en que Play las enseña, que es el
# del numero; `Index` es la posicion del estado en la lista de
# `scripts/capture_main.dart`, que es por donde se pasa en el telefono.
#
# Los dos ordenes ya no coinciden, y por eso son dos columnas. `capture_main`
# tiene mas estados de los que van a la ficha: unos porque solo sirven para
# mirar algo en el telefono (el rival con el turno gastado, la segunda parte,
# el velo con Time-Out) y el aviso previo porque se cayo de la ficha. Y el
# acta, que cierra el relato del partido, es el ultimo estado del recorrido
# pero va antes que los ajustes en la ficha: se fotografia la septima y se
# guarda como la `07`.
#
# La lista tiene que ir en orden de `Index` creciente: el recorrido solo avanza.
$shots = @(
    @{ File = '01-antes-de-empezar';           Index = 1 },
    @{ File = '02-turno-corriendo';            Index = 2 },
    @{ File = '03-tiempo-extra-consumiendose'; Index = 4 },
    @{ File = '04-overtime';                   Index = 5 },
    @{ File = '05-pausado';                    Index = 6 },
    @{ File = '06-nombres';                    Index = 7 },
    @{ File = '08-ajustes';                    Index = 8 },
    @{ File = '07-acta';                       Index = 12 }
)

# Si alguien reordena la lista sin darse cuenta, el recorrido se queda corto y
# salen capturas repetidas. Mejor decirlo aqui que descubrirlo mirandolas.
for ($i = 1; $i -lt $shots.Count; $i++) {
    if ($shots[$i].Index -le $shots[$i - 1].Index) {
        throw "La lista va en orden de Index: $($shots[$i].File) no puede ir detras de $($shots[$i - 1].File)"
    }
}

# Lo que se espera antes de disparar, para que no salga nada a medio dibujar.
#
# Lo marca la animacion mas larga de las que se fotografian, que ya no es la
# presentacion del escudo (dos segundos y pico, en cada arranque) sino el acta
# montandose, que dura cuatro y pico. Con los cinco de antes la captura del
# acta caia justo encima del final de su animacion.
#
# El margen es generoso a proposito: una captura mala no se nota hasta que se
# mira, y repetir la tanda cuesta mas que esperar. Si se vuelve a tocar
# `ClockTheme.reportRevealDuration`, hay que volver a mirar esto.
$revealWait = 7

$adb = if ($Serial) { @('-s', $Serial) } else { @() }
$package = 'com.ares.bloodbowl.turnover'
$remoteShot = '/sdcard/turnover-capture.png'

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
}

# Por que estado del recorrido va el telefono. Arranca en el primero.
$current = 0

for ($i = 0; $i -lt $shots.Count; $i++) {
    $shot = $shots[$i]
    $target = Join-Path $OutDir "$($shot.File).png"
    Write-Host "[$($i + 1)/$($shots.Count)] $($shot.File)  (estado $($shot.Index))"

    # La primera arranca la aplicacion; a las siguientes se llega con toques en
    # la banda del borde izquierdo, que es lo que pasa al estado siguiente.
    if ($i -eq 0) {
        & adb @adb shell am force-stop $package
        & adb @adb shell am start -n "$package/.MainActivity" | Out-Null
        $current = 1
    }

    while ($current -lt $shot.Index) {
        & adb @adb shell input tap 14 1200
        $current++
        # Los estados por los que solo se pasa no se fotografian, asi que no
        # hay que esperar a que el escudo termine de dibujarse: basta con que
        # al toque le de tiempo a llegar y a rehacer la pantalla.
        if ($current -lt $shot.Index) { Start-Sleep -Milliseconds 700 }
    }
    Start-Sleep -Seconds $revealWait

    & adb @adb shell screencap -p $remoteShot
    & adb @adb pull -a $remoteShot $target 2>&1 | Out-Null
    & adb @adb shell rm -f $remoteShot

    if (-not (Test-Path $target)) {
        throw "No se ha traido la captura $($shot.File)"
    }
    $size = (Get-Item $target).Length
    if ($size -lt 10000) {
        throw "La captura $($shot.File) ha salido vacia ($size bytes)"
    }
}

& adb @adb shell am force-stop $package

# Dos capturas iguales quieren decir que el estado no se sembro y que la tanda
# no vale: es el fallo que ya se colo una vez, y en miniatura no se ve.
$hashes = @{}
foreach ($shot in $shots) {
    $target = Join-Path $OutDir "$($shot.File).png"
    $hash = (Get-FileHash $target -Algorithm MD5).Hash
    if ($hashes.ContainsKey($hash)) {
        throw "$($shot.File) ha salido igual que $($hashes[$hash]): el estado no se ha sembrado"
    }
    $hashes[$hash] = $shot.File
}

Write-Host ''
Write-Host "Listo: $($shots.Count) capturas en $OutDir"
Write-Host 'Repasalas antes de subirlas: el reloj de cada una tiene que ser el que dice su nombre.'
