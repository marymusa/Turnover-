#!/usr/bin/env bash
# Toma las ocho capturas de la ficha de App Store y las deja en
# store/app-store/<idioma>/screenshots/.
#
# Uso:
#   ./scripts/tomar-capturas-ios.sh              es-ES en el iPhone 17 Pro Max
#   ./scripts/tomar-capturas-ios.sh --idioma en  la tanda en ingles
#   ./scripts/tomar-capturas-ios.sh --aparato "iPhone 17 Pro"
#
# El hermano de scripts/tomar-capturas.ps1, que hace lo mismo en Android. La
# lista de capturas es la misma y las comprobaciones del final tambien.
#
# Lo que cambia es como se recorre. En Android se llega a cada estado tocando la
# banda del borde izquierdo, porque adb sabe tocar. simctl no: sabe arrancar,
# fotografiar y matar, pero no tocar la pantalla. Asi que aqui la aplicacion se
# arranca una vez por captura, dejandole antes una nota con la que le toca. Sale
# mas lento y menos fragil: no hay cadena de toques que se pueda quedar a medias
# sin avisar.
#
# La nota es un fichero en el tmp del contenedor de la aplicacion, que en el
# simulador es una carpeta normal del Mac. No se usa el entorno porque no llega:
# SIMCTL_CHILD_... no cruza hasta Dart, que ve Platform.environment vacia. Se
# comprobo midiendolo, despues de una tanda entera de ocho capturas iguales.
#
# App Store pide las capturas de 6,9 pulgadas a 1320x2868, que es justo lo que
# da el iPhone 17 Pro Max. El script comprueba el tamano antes de dar la tanda
# por buena: una captura del simulador equivocado entra igual y no se ve hasta
# que la tienda la rechaza.

set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/development/flutter/bin:$PATH"

aparato='iPhone 17 Pro Max'
idioma='es'
carpeta=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aparato) aparato="$2"; shift 2 ;;
    --idioma) idioma="$2"; shift 2 ;;
    --salida) carpeta="$2"; shift 2 ;;
    *) echo "No conozco la opcion $1" >&2; exit 1 ;;
  esac
done

case "$idioma" in
  es) region='es-ES' ;;
  en) region='en-US' ;;
  *) echo "El idioma es 'es' o 'en', no '$idioma'" >&2; exit 1 ;;
esac
# La carpeta se decide mas abajo, cuando se sepa que ranura pide el aparato.

# Las ocho de la ficha. La primera columna manda el orden en que la tienda las
# ensena, que es el del numero; la segunda es la posicion del estado en la lista
# de scripts/capture_main.dart, contando desde cero.
#
# Los dos ordenes no coinciden, igual que en Android: capture_main tiene mas
# estados de los que van a la ficha, y el acta, que cierra el relato del
# partido, es el ultimo del recorrido pero va antes que los ajustes en la ficha.
capturas=(
  '01-antes-de-empezar:0'
  '02-turno-corriendo:1'
  '03-tiempo-extra-consumiendose:3'
  '04-overtime:4'
  '05-pausado:5'
  '06-nombres:6'
  '08-ajustes:7'
  '07-acta:11'
)

# Lo que se espera antes de disparar, para que no salga nada a medio dibujar.
# Lo marca el acta montandose, que dura cuatro segundos y pico. El margen es
# generoso a proposito: una captura mala no se nota hasta que se mira, y
# repetir la tanda cuesta mas que esperar. Si se vuelve a tocar
# ClockTheme.reportRevealDuration, hay que volver a mirar esto.
espera=7

paquete='com.ares.bloodbowl.turnover'

# Cada ranura de la ficha tiene su tamano y no admite otro. El que toca sale del
# simulador, no de una constante: con --aparato se puede pedir otra ranura, y
# una cifra fija aqui haria fallar cualquier aparato que no fuera el de 6,9".
#
# Comprobado en este Mac: el 17 Pro Max da 1320x2868 y el 14 Plus 1284x2778.
case "$aparato" in
  'iPhone 17 Pro Max') ancho_pedido=1320; alto_pedido=2868; ranura='' ;;
  'iPhone 14 Plus')    ancho_pedido=1284; alto_pedido=2778; ranura='-6.7' ;;
  *)
    echo "No se que tamano pide '$aparato'." >&2
    echo "Anadelo aqui con el suyo antes de usarlo: una captura del tamano" >&2
    echo "equivocado entra igual y no se ve hasta que la tienda la rechaza." >&2
    exit 1
    ;;
esac

# La ranura de 6,9" es la principal y se queda en `screenshots/` a secas; las
# demas llevan su medida en el nombre. Sin esto una tanda de 6,7" pisaria la de
# 6,9" y las dos ranuras acabarian con las mismas imagenes.
[[ -n "$carpeta" ]] || carpeta="store/app-store/$region/screenshots$ranura"

udid="$(xcrun simctl list devices available -j \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
for runtime, aparatos in d.items():
    if 'iOS' not in runtime: continue
    for a in aparatos:
        if a['name'] == '''$aparato''':
            print(a['udid']); raise SystemExit
")"

if [[ -z "$udid" ]]; then
  echo "No encuentro ningun simulador que se llame '$aparato'." >&2
  echo "Los que hay: xcrun simctl list devices available" >&2
  exit 1
fi

echo "Aparato:  $aparato ($udid)"
echo "Idioma:   $idioma"
echo "Salida:   $carpeta"
echo

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b > /dev/null

echo "Compilando el entrypoint de capturas..."
flutter build ios --simulator --debug -t scripts/capture_main.dart > /dev/null
xcrun simctl install "$udid" build/ios/iphonesimulator/Turnover.app

# Donde se le deja la nota. El contenedor se pide despues de instalar, porque
# instalar de nuevo puede cambiarlo de sitio.
contenedor="$(xcrun simctl get_app_container "$udid" "$paquete" data)"
nota="$contenedor/tmp/turnover-captura.txt"
mkdir -p "$(dirname "$nota")"

mkdir -p "$carpeta"

total=${#capturas[@]}
for i in "${!capturas[@]}"; do
  nombre="${capturas[$i]%%:*}"
  estado="${capturas[$i]##*:}"
  destino="$carpeta/$nombre.png"
  printf '[%d/%d] %-34s (estado %s)\n' "$((i + 1))" "$total" "$nombre" "$estado"

  xcrun simctl terminate "$udid" "$paquete" 2>/dev/null || true
  printf '%s\n%s\n' "$estado" "$idioma" > "$nota"
  xcrun simctl launch "$udid" "$paquete" > /dev/null

  sleep "$espera"
  xcrun simctl io "$udid" screenshot "$destino" 2>/dev/null

  [[ -f "$destino" ]] || { echo "No se ha tomado la captura $nombre" >&2; exit 1; }

  bytes=$(stat -f%z "$destino")
  if (( bytes < 10000 )); then
    echo "La captura $nombre ha salido vacia ($bytes bytes)" >&2
    exit 1
  fi

  ancho=$(sips -g pixelWidth "$destino" | awk '/pixelWidth/{print $2}')
  alto=$(sips -g pixelHeight "$destino" | awk '/pixelHeight/{print $2}')
  if [[ "$ancho" != "$ancho_pedido" || "$alto" != "$alto_pedido" ]]; then
    echo "La captura $nombre mide ${ancho}x${alto} y App Store pide ${ancho_pedido}x${alto_pedido}." >&2
    echo "Es el simulador equivocado: para 6,9 pulgadas hace falta un iPhone 17 Pro Max." >&2
    exit 1
  fi
done

xcrun simctl terminate "$udid" "$paquete" 2>/dev/null || true

# Dos capturas iguales quieren decir que el estado no se sembro y que la tanda
# no vale: es el fallo que ya se colo una vez en Android, y en miniatura no se
# ve.
# La suma se hace sin la barra de estado. En Android bastaba con la del fichero
# entero, pero aqui el reloj del simulador cambia entre captura y captura: ocho
# capturas identicas salen con ocho sumas distintas y la comprobacion no ve
# nada. Es justo lo que paso la primera vez que se corrio esto.
recorte="$(mktemp -d)"
trap 'rm -rf "$recorte"' EXIT
sin_barra=200

# El bash de macOS es el 3.2 y con `set -u` una lista vacia no se puede
# recorrer, asi que hay que mirar antes si tiene algo.
declare -a vistas=()
for par in "${capturas[@]}"; do
  nombre="${par%%:*}"
  sips -c "$((alto_pedido - sin_barra))" "$ancho_pedido" \
    --cropOffset "$sin_barra" 0 \
    "$carpeta/$nombre.png" --out "$recorte/$nombre.png" > /dev/null
  suma=$(md5 -q "$recorte/$nombre.png")
  if (( ${#vistas[@]} > 0 )); then
    for anterior in "${vistas[@]}"; do
      if [[ "${anterior%%:*}" == "$suma" ]]; then
        echo "$nombre ha salido igual que ${anterior##*:}: el estado no se ha sembrado" >&2
        exit 1
      fi
    done
  fi
  vistas+=("$suma:$nombre")
done

echo
echo "Listo: $total capturas en $carpeta"
echo 'Repasalas antes de subirlas: el reloj de cada una tiene que ser el que dice su nombre.'
