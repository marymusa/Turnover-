import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/ui/clock_colors.dart';

/// La razón de contraste entre dos colores opacos, como la define WCAG 2.
///
/// Es la comprobación que los comentarios de la paleta oscura describían a
/// mano: los valores no son decorativos, salieron de medir. Aquí se mide sola,
/// para que la paleta clara no se elija a ojo y para que ninguna de las dos se
/// pueda retocar rompiendo lo que la sostiene.
double _contrast(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color color) => color.computeLuminance();

/// Lo que se ve de verdad cuando un color translúcido se pinta encima de otro.
/// Las alfas de la paleta no se miden solas: lo que lee el jugador es la
/// mezcla.
Color _over(Color front, Color back) =>
    Color.alphaBlend(front, back);

void main() {
  for (final palette in [ClockColors.dark, ClockColors.light]) {
    final name = palette == ClockColors.dark ? 'oscura' : 'clara';

    group('paleta $name', () {
      test('los relojes se leen sobre las dos mitades activas', () {
        expect(
          _contrast(palette.text, palette.active),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(palette.text, palette.activeOpponent),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('los relojes se leen sobre la mitad inactiva', () {
        expect(
          _contrast(palette.text, palette.inactive),
          greaterThanOrEqualTo(4.5),
        );
      });

      // El fondo de la pantalla no lleva la letra de las tarjetas: lleva la
      // suya, que es la que cambia de claro a oscuro.
      test('los ajustes se leen sobre el fondo de la pantalla', () {
        expect(
          _contrast(palette.onSurface, palette.background),
          greaterThanOrEqualTo(4.5),
        );
      });

      // El amarillo de la paleta oscura era el único color que pasaba de 5:1
      // sobre las dos mitades. La clara necesita otro, pero la condición que
      // lo eligió es la misma y se comprueba igual.
      test('el tiempo extra agotado avisa sobre las dos mitades', () {
        expect(_contrast(palette.reserve, palette.active), greaterThan(5));
        expect(
          _contrast(palette.reserve, palette.activeOpponent),
          greaterThan(5),
        );
      });

      test('el tiempo extra agotado avisa sobre la mitad inactiva', () {
        expect(_contrast(palette.reserve, palette.inactive), greaterThan(5));
      });

      // El control de pausa encendido lleva la letra del tema encima. Es un
      // icono y no texto, así que se le pide el 3:1 de los elementos gráficos
      // y no el 4,5:1 de lectura.
      test('el icono del control pausado se ve', () {
        expect(_contrast(palette.text, palette.paused), greaterThan(3));
      });

      // El velo deja ver los relojes por debajo, pero su aviso se lee sobre lo
      // que el velo deja: fondo con la opacidad del velo encima de una mitad.
      test('el aviso de pausa se lee a través del velo', () {
        for (final under in [palette.active, palette.activeOpponent]) {
          final veiled = _over(
            palette.background.withValues(alpha: palette.veilOpacity),
            under,
          );
          expect(
            _contrast(palette.veilText, veiled),
            greaterThanOrEqualTo(4.5),
            reason: 'el velo sobre $under',
          );
        }
      });

      // Los controles avanzados van apagados a propósito, pero apagado no es
      // invisible: su icono tiene que despegarse de la mitad que tiene detrás.
      test('los iconos de la costura se despegan del relleno', () {
        final fill = _over(
          palette.onSurface.withValues(alpha: palette.advancedFillAlpha),
          palette.background,
        );
        final icon = _over(
          palette.onSurface.withValues(alpha: palette.advancedIconAlpha),
          fill,
        );
        expect(_contrast(icon, fill), greaterThanOrEqualTo(2.5));
      });

      // El borde de la tarjeta separa la mitad del fondo. No es texto, así que
      // no se le pide contraste de lectura, pero tiene que verse.
      test('el borde de la tarjeta se ve sobre la mitad inactiva', () {
        final border = _over(
          palette.text.withValues(alpha: palette.halfCardBorderAlpha),
          palette.inactive,
        );
        expect(_contrast(border, palette.inactive), greaterThan(1.1));
      });
    });
  }

  test('las dos paletas dicen de quién es el turno con el mismo par', () {
    // Azul y naranja en las dos: el color es lo único que dice de quién es el
    // turno, y esa lectura tiene que sobrevivir al cambio de fondo aunque los
    // valores exactos no sean los mismos.
    expect(ClockColors.light.active, isNot(ClockColors.dark.active));
    expect(
      ClockColors.light.activeOpponent,
      isNot(ClockColors.dark.activeOpponent),
    );
    expect(
      _hue(ClockColors.light.active),
      closeTo(_hue(ClockColors.dark.active), 20),
    );
    expect(
      _hue(ClockColors.light.activeOpponent),
      closeTo(_hue(ClockColors.dark.activeOpponent), 20),
    );
  });

  test('la paleta clara es clara y la oscura oscura', () {
    expect(ClockColors.light.background.computeLuminance(), greaterThan(0.5));
    expect(ClockColors.dark.background.computeLuminance(), lessThan(0.1));
  });
}

double _hue(Color color) => HSLColor.fromColor(color).hue;
