# Turnover!

Cronómetro de turno y reserva para partidas de Blood Bowl. Un solo móvil sobre la mesa,
dos jugadores, sin red y sin sincronización.

El modelo de dominio vive en [`CONTEXT.md`](CONTEXT.md) y las decisiones difíciles de
revertir en [`docs/adr/`](docs/adr).

## Empezar

```sh
flutter pub get
flutter run
```

`flutter pub get` genera las clases de localización a partir de los `.arb`, así que hay
que ejecutarlo antes que nada en un clon recién hecho.

## En el emulador

```powershell
.\scripts\run-emulator.ps1
.\scripts\run-app.ps1
```

El primero enciende el emulador y espera a que termine de arrancar, porque
`flutter emulators --launch` vuelve antes de que el aparato esté listo. El segundo
instala y arranca la aplicación en el emulador que encuentre. Con `-Clean` para los
demonios de Gradle y borra `build/` antes de compilar, que es lo que hace falta cuando
una compilación deja la carpeta bloqueada.

La compilación incremental de Kotlin queda desactivada en
`android/gradle.properties`. Con ella puesta, la compilación de Android falla siempre
con `Could not close incremental caches` en cualquier plugin que traiga código Kotlin
(`shared_preferences_android`, `audioplayers_android`). Apagarla solo cuesta tiempo de
recompilación.

## Comprobaciones

```sh
flutter analyze
flutter test
```

## Textos

Todas las cadenas viven en `lib/l10n/`, en castellano e inglés. Para añadir una, se
escribe en `app_en.arb`, que hace de plantilla, y se traduce en `app_es.arb`.

Las clases `app_localizations*.dart` son generadas y no se versionan: la fuente son los
`.arb`. El idioma sale de la configuración del sistema y el inglés hace de alternativa.
