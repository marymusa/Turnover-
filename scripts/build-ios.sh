#!/usr/bin/env bash
# Compila el archivo (.xcarchive) y el .ipa de la aplicacion para App Store.
#
# Uso:
#   ./scripts/build-ios.sh          compila con lo que haya
#   ./scripts/build-ios.sh --clean  borra build/ y los pods antes de compilar
#
# La firma va a mano, no automatica. La cuenta de desarrollador no tiene
# ningun aparato dado de alta, y sin aparatos Apple no deja crear un perfil de
# desarrollo; el de App Store no lo necesita. Por eso Release usa el perfil
# TurnoverAppStore y el certificado Apple Distribution, igual que LazyMeeple.
# Lo demas esta en ios/ExportOptions.plist.
#
# Necesita el numero de compilacion de pubspec.yaml (lo que va detras del +)
# mayor que el de cualquier compilacion ya subida a App Store Connect.
#
# Sube el resultado a mano: abre build/ios/archive/Runner.xcarchive en Xcode
# (Distribute App) o arrastra el .ipa a Transporter.

set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/development/flutter/bin:$PATH"

if ! command -v flutter >/dev/null; then
  echo "No encuentro flutter en ~/development/flutter/bin" >&2
  exit 1
fi

if [[ "${1:-}" == "--clean" ]]; then
  echo "Limpiando..."
  flutter clean
  rm -rf ios/Pods ios/Podfile.lock
fi

version="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo "Version $version"

perfil="$(/usr/libexec/PlistBuddy -c 'Print :provisioningProfiles:com.ares.bloodbowl.turnover' ios/ExportOptions.plist)"

# Sin el perfil descargado la compilacion falla al final, despues de varios
# minutos. Mejor decirlo ahora.
if ! grep -lq "$perfil" ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.mobileprovision 2>/dev/null; then
  echo "No encuentro el perfil '$perfil' en este ordenador." >&2
  echo "Creale uno de App Store en developer.apple.com (Profiles > +," >&2
  echo "Distribution > App Store Connect) con ese nombre exacto y descargalo." >&2
  exit 1
fi

flutter pub get

# Con Swift Package Manager no hay Podfile y no hay nada que instalar; solo
# aparece si algun complemento todavia necesita CocoaPods.
if [[ -f ios/Podfile ]]; then
  (cd ios && pod install)
fi

# Si cambia PRODUCT_NAME, el archivo viejo se queda al lado del nuevo con otro
# nombre y luego no se sabe cual se sube.
rm -rf build/ios/archive build/ios/ipa

flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# En la lista del Organizer de Xcode el archivo sale con el nombre del esquema,
# y en Flutter el esquema se llama siempre "Runner". El esquema no se puede
# renombrar sin romper el propio flutter build, asi que se corrige aqui. Es
# solo como se ve en la lista: no toca la firma ni el paquete.
archivo="$(ls -d build/ios/archive/*.xcarchive | head -1)"
/usr/libexec/PlistBuddy -c 'Set :Name Turnover!' "$archivo/Info.plist"

echo
echo "Listo, version $version:"
ls -d build/ios/archive/*.xcarchive build/ios/ipa/*.ipa
