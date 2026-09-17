# Crea la clave con la que se firma la aplicacion para Play Store.
#
# EJECUTALO TU, no un agente: keytool pide la contrasena por teclado y asi no
# pasa por ningun sitio que la registre. Se escribe una vez aqui y otra en el
# gestor de contrasenas, y no se guarda en ningun otro lado.
#
# La clave NO se puede recuperar. Perderla impide publicar cualquier
# actualizacion de la aplicacion para siempre: Play identifica una aplicacion
# por su firma, y sin la clave original no hay forma de firmar igual. Haz copia
# de seguridad del .jks en dos sitios distintos antes de subir nada.
#
# Escribe dos ficheros, los dos fuera del repositorio por el .gitignore:
#   android/upload-keystore.jks   la clave
#   android/key.properties        donde esta y como abrirla

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$keystore = Join-Path (Get-Location) 'android\upload-keystore.jks'
$properties = Join-Path (Get-Location) 'android\key.properties'
$alias = 'upload'

if (Test-Path $keystore) {
  Write-Host ''
  Write-Host "Ya existe una clave en $keystore" -ForegroundColor Yellow
  Write-Host 'No se toca: sobrescribirla dejaria la aplicacion sin poder actualizarse.'
  Write-Host 'Para rehacerla desde cero, muevela a otro sitio a mano y vuelve a ejecutar esto.'
  exit 1
}

# keytool viene con el JDK. Android Studio trae el suyo, que es el que se usa
# si no hay ninguno en el PATH.
$keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
if (-not $keytool) {
  $candidates = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe"
  )
  $keytool = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $keytool) {
  Write-Host 'No se encuentra keytool.' -ForegroundColor Red
  Write-Host 'Viene con el JDK. Si tienes Android Studio, esta en su carpeta jbr\bin.'
  Write-Host 'Instala un JDK o pon JAVA_HOME apuntando al que tengas.'
  exit 1
}

Write-Host ''
Write-Host 'Clave de firma de Turnover!' -ForegroundColor Cyan
Write-Host ''
Write-Host 'keytool va a pedirte:'
Write-Host '  1. Una contrasena para la clave. Minimo 6 caracteres.'
Write-Host '     Guardala en tu gestor de contrasenas ANTES de seguir.'
Write-Host '  2. Tus datos (nombre, organizacion, ciudad, pais).'
Write-Host '     Solo viajan dentro del certificado, no se publican en la ficha.'
Write-Host '     Se puede dejar en blanco todo menos el primero.'
Write-Host ''
Write-Host 'La clave vale 10000 dias, unos 27 anos: Play exige que no caduque'
Write-Host 'antes de 2033.'
Write-Host ''

& $keytool -genkeypair -v `
  -keystore $keystore `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias $alias

if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host 'keytool ha fallado. No se ha creado nada.' -ForegroundColor Red
  exit 1
}

Write-Host ''
Write-Host 'Clave creada. Ahora hace falta la misma contrasena en key.properties,' -ForegroundColor Cyan
Write-Host 'que es de donde la lee Gradle al compilar la version de release.'
Write-Host ''
$secret = Read-Host 'Escribe otra vez la contrasena' -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
)

# La ruta va relativa a android/, que es desde donde la resuelve Gradle.
#
# Sin BOM a proposito: Properties.load() de Java lee el fichero como
# ISO-8859-1, y el BOM que mete "-Encoding utf8" se pega a la primera clave.
# Quedaria "﻿storePassword", que Gradle no encuentra, y la firma caeria
# sin avisar en la clave de depuracion. Todo lo que se escribe aqui es ASCII.
$texto = @(
  "storePassword=$plain",
  "keyPassword=$plain",
  "keyAlias=$alias",
  "storeFile=upload-keystore.jks"
) -join "`n"
[IO.File]::WriteAllText($properties, $texto + "`n", [Text.UTF8Encoding]::new($false))

Write-Host ''
Write-Host 'Listo.' -ForegroundColor Green
Write-Host ''
Write-Host "  Clave:      $keystore"
Write-Host "  Contrasena: $properties"
Write-Host ''
Write-Host 'Los dos estan en el .gitignore y no se suben al repositorio.' -ForegroundColor Yellow
Write-Host 'Haz copia de seguridad del .jks AHORA, en dos sitios distintos.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Comprueba que la firma entra con:'
Write-Host '  flutter build appbundle --release'
