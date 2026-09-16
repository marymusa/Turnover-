/// El adaptador que mantiene encendida la pantalla del aparato. Nada del
/// dominio entra aquí: solo se pide o se suelta el wakelock.
library;

import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/awake_guard.dart';

class PlatformScreen implements Screen {
  const PlatformScreen();

  @override
  Future<void> keepOn(bool on) => WakelockPlus.toggle(enable: on);
}
