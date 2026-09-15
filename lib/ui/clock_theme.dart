import 'package:flutter/material.dart';

/// Los colores y las medidas que fijó el prototipo B2. Viven juntos y en un
/// solo sitio porque la pantalla es una sola y todas se eligieron a la vez,
/// mirándolas en un móvil de verdad.
abstract final class ClockTheme {
  static const background = Color(0xFF0B0F19);
  static const inactive = Color(0xFF161B26);
  static const active = Color(0xFF1D4ED8);
  static const text = Color(0xFFF8FAFC);
  static const reserve = Color(0xFFF59E0B);

  /// Solo la lleva el control de pausa mientras está pausado, que es el único
  /// sitio donde hace falta decir "esto está detenido a propósito".
  static const paused = Color(0xFF16A34A);

  /// El turno encoge y la reserva crece al agotarse el turno. Ninguno de los
  /// dos se mueve de sitio: solo cambian de tamaño y de color.
  static const turnSize = 96.0;
  static const turnSizeSpent = 40.0;
  static const reserveSize = 26.0;
  static const reserveSizeSpent = 60.0;

  static const passTurnSize = 74.0;
  static const passTurnIconSize = 30.0;
  static const advancedSize = 40.0;
  static const advancedIconSize = 15.0;

  /// Lo que separa los tres controles de la costura.
  static const seamGap = 26.0;

  /// El jugador inactivo no se apaga del todo: se sigue leyendo desde el otro
  /// lado de la mesa.
  static const inactiveOpacity = 0.3;

  static const barHeight = 6.0;
  static const barWidthFactor = 0.74;
}
