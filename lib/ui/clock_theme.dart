import 'dart:math' as math;
import 'dart:ui' show Size;

/// Las medidas que fijó el prototipo B2. Viven juntas y en un solo sitio
/// porque la pantalla es una sola y todas se eligieron a la vez, mirándolas en
/// un móvil de verdad.
///
/// Solo medidas y tiempos: lo que mide un dedo mide igual de día que de noche.
/// Los colores se fueron a [ClockColors] cuando la aplicación pasó a seguir el
/// modo claro del aparato, porque de esos hay dos juegos y de estos uno.
abstract final class ClockTheme {
  /// El turno encoge y la reserva crece al agotarse el turno. Ninguno de los
  /// dos se mueve de sitio: solo cambian de tamaño y de color.
  static const turnSize = 96.0;
  static const turnSizeSpent = 40.0;
  static const reserveSize = 26.0;
  static const reserveSizeSpent = 60.0;

  /// El nombre se lee, pero no compite con los relojes: es una etiqueta.
  static const nameSize = 16.0;

  /// El lápiz que anuncia el cambio de nombre, al lado del nombre, y la pista
  /// que lo acompaña. Menores que la letra del nombre: acompañan, no encabezan.
  static const renameIconSize = 14.0;
  static const renameHintSize = 11.0;

  /// Los tres controles de la costura, a tamaño de dedo. El objetivo táctil
  /// mínimo que piden Material y Apple es de 48 píxeles, y los dos avanzados
  /// lo pasan con margen: en una mesa se golpea la pantalla sin apuntar, y a
  /// 40 se fallaba el de pausa.
  ///
  /// Pasar turno sigue siendo claramente el mayor. Lo que manda en la costura
  /// lo dice el tamaño, y por eso los otros dos pueden crecer sin quitarle
  /// nada: la jerarquía estaba en la diferencia, no en que fueran pequeños.
  ///
  /// El botón de los ajustes comparte [advancedSize] y crece con ellos, que es
  /// lo que se quiere: es un objetivo de dedo como los demás.
  static const passTurnSize = 96.0;
  static const passTurnIconSize = 38.0;
  static const advancedSize = 56.0;
  static const advancedIconSize = 21.0;

  /// Lo que separa los tres controles de la costura.
  static const seamGap = 26.0;

  /// Lo que se levantan los controles de la costura. Pasar turno va más alto
  /// que los otros dos: en Material la altura dice cuál manda, y aquí manda
  /// el que pasa el turno.
  static const controlElevation = 3.0;
  static const passTurnElevation = 6.0;

  /// Lo que el botón de los ajustes se aparta del centro, medido hasta su
  /// propio centro: media anchura de escudo, media de botón y el hueco de la
  /// costura entre los dos. El escudo no se mueve de sitio, que es el centro
  /// del campo, y el botón se coloca a su lado sin empujarlo.
  ///
  /// El hueco va entero y no a la mitad: con la mitad el botón quedaba rozando
  /// la mandíbula del escudo. El escudo llena su caja casi hasta el borde, así
  /// que lo que separa a los dos es esto y nada más.
  static const settingsOffset = leagueLogoSize / 2 + advancedSize / 2 + seamGap;

  /// La mitad no llega hasta el borde: el color vive dentro de una tarjeta, y
  /// el fondo de la pantalla se ve alrededor. Lo que se aparta es poco a
  /// propósito, que el alto de la pantalla ya va justo con los dos relojes.
  ///
  /// El toque no se encoge con ella: sigue cogiendo la mitad entera, márgenes
  /// incluidos. En una mesa se golpea la pantalla, no se apunta.
  static const halfCardInset = 12.0;

  /// Arriba y abajo, cada tarjeta se aparta la mitad. En la costura las dos se
  /// suman y el hueco sale entero; contra el borde de la pantalla no hay otra
  /// tarjeta que sume, así que la mitad que falta la pone la pantalla.
  static const halfCardVerticalInset = halfCardInset / 2;
  static const halfCardRadius = 20.0;
  static const halfCardBorderWidth = 1.0;

  /// La cuenta de turnos, al pie de cada tarjeta. Una casilla es más ancha que
  /// alta porque en la segunda parte los números son de dos cifras: el ancho lo
  /// fija el 16, y las dos partes miden igual para que la fila no cambie de
  /// forma al pasar de una a otra.
  ///
  /// Por debajo del objetivo táctil mínimo de Material, que son 48, y a
  /// propósito: las casillas no se pulsan una a una, son un indicador.
  static const turnBoxWidth = 30.0;
  static const turnBoxHeight = 26.0;

  /// Lo que separa una casilla de la siguiente, a cada lado.
  static const turnBoxGap = 3.0;

  /// El radio `small` de las formas de Material, que es el que llevan los
  /// contenedores de este tamaño.
  static const turnBoxRadius = 8.0;

  /// Lo que la fila se despega de la pared interior de la tarjeta, igual por
  /// los tres lados. Se suma al margen de la propia tarjeta, que no es el mismo
  /// a los lados que abajo: sin sumarlo, la fila se quedaba rozando la pared
  /// por dentro, porque vive dentro de la tarjeta y no fuera.
  ///
  /// Cubre de sobra el radio de la esquina, que a 20 pide unos 6 para que una
  /// casilla no se meta debajo del arco.
  static const turnCountInset = 16.0;

  /// Lo que se apaga un turno ya jugado o todavía por jugar. Es lo que los
  /// distingue del que corre, que va entero.
  ///
  /// Apagado no es borrado: el 38% que Material da para lo deshabilitado se
  /// queda en 2,2:1 sobre el azul y sobre el naranja, y una fila que hay que
  /// contar de un vistazo no se cuenta a esa distancia. El 55% es el primer
  /// valor que pasa el 3:1 de los elementos gráficos sobre las tres tarjetas y
  /// en las dos paletas, que es lo que mide `test/clock_colors_test.dart`.
  static const dimmedContentOpacity = 0.55;

  /// Lo que se rellena la casilla de un turno ya jugado, que es lo que lo
  /// separa del que está por jugar sin darle el peso del que corre.
  ///
  /// El 12% de Material vale sobre la mitad activa, donde la tinta es clara
  /// sobre un color saturado. Sobre la que espera no: ahí la tinta es oscura
  /// sobre una tarjeta que en la paleta clara es casi blanca, y al 12%
  /// desaparecía, de modo que la fila entera se quedaba en blanco sobre
  /// blanco.
  ///
  /// Es el mismo motivo por el que hay [ClockColors.reserve] y
  /// [ClockColors.inactiveReserve]: las dos mitades dejaron de compartir fondo.
  static const playedFillOpacity = 0.12;
  static const waitingPlayedFillOpacity = 0.22;

  /// Solo la casilla del turno en curso se levanta. En Material la elevación
  /// dice cuál manda, y aquí manda el turno que se está jugando.
  static const turnBoxElevation = 2.0;

  static const veilTextSize = 19.0;

  /// El botón de Time-Out, debajo del aviso del velo. Su alto sale del texto y
  /// del relleno, que juntos pasan de los 48 del objetivo táctil mínimo: este
  /// sí se pulsa, al revés que las casillas de la cuenta.
  static const veilButtonGap = 20.0;

  /// Lo que encabeza el botón, diciendo de qué tabla sale. Menor que el aviso
  /// del velo y que el propio botón: acompaña, no encabeza la pantalla.
  static const veilLabelSize = 12.0;
  static const veilLabelGap = 8.0;

  /// La ficha con el resultado de la tabla que va dentro del botón, delante del
  /// nombre. Cuadrada como las casillas de la cuenta y con su mismo radio: en
  /// esta pantalla un número en un cuadrado ya significa una casilla.
  static const veilBadgeSize = 24.0;
  static const veilBadgeTextSize = 14.0;
  static const veilBadgeGap = 10.0;

  /// Lo que se tiñe la ficha sobre la superficie del botón. Poco: lo que tiene
  /// que destacar es el número, y la ficha solo lo encuadra.
  static const veilBadgeFillOpacity = 0.1;
  static const veilButtonTextSize = 16.0;
  static const veilButtonHorizontalPadding = 28.0;
  static const veilButtonVerticalPadding = 15.0;

  /// Lo que el contenido del velo baja desde el centro, que es donde está la
  /// costura: media altura del control de pasar turno, que es el más grande de
  /// los tres, y un respiro por debajo de su sombra.
  ///
  /// Se mide desde el centro y no desde el borde de la pantalla porque lo que
  /// tiene que esquivar es la costura, que está en el centro pase lo que pase
  /// con el alto del aparato.
  static const veilContentTop = passTurnSize / 2 + 24;

  /// El acta. No se reparte en dos mitades como el resto de la pantalla: es
  /// un documento y se lee entera de arriba abajo, en una sola orientación,
  /// porque lo que se hace con ella es una captura que va al responsable de
  /// la liga, que la lee como cualquier otra imagen.
  ///
  /// Lo ancho va topado para que la etiqueta y su cifra no se vayan a los dos
  /// bordes de la pantalla, que es donde dejan de leerse como una pareja.
  static const reportWidth = 300.0;

  /// El rótulo que encabeza el acta y dice que el partido ha terminado.
  /// Comparte cuerpo con el que encabeza el botón del velo: los dos son la
  /// misma clase de rótulo, el que nombra lo que viene debajo.
  static const reportHeadingSize = veilLabelSize;
  static const reportHeadingGap = 26.0;

  /// Las dos filas de los jugadores, que son lo comparable del acta y por eso
  /// van por encima de las otras dos y con mayor cuerpo. El nombre no compite
  /// con su tiempo: es una etiqueta, igual que en la mitad de cada jugador.
  static const reportPlayerTimeSize = 28.0;

  /// El nombre va bastante por debajo de su tiempo: en esta fila lo que se
  /// compara son los dos números, y el nombre solo dice de quién es cuál.
  static const reportPlayerNameSize = 13.0;

  /// La pastilla del color con el que cada jugador ha jugado, delante de su
  /// nombre. Pequeña a propósito: en un documento el color acompaña al
  /// nombre, y una fila entera teñida haría que la captura pareciera la
  /// pantalla de juego en vez de un acta.
  static const reportAccentSize = 10.0;
  static const reportAccentGap = 10.0;

  /// El tiempo de juego, que es la cifra que encabeza el acta, y el total
  /// debajo. La grande va sin cifras tabulares a propósito: las tabulares
  /// alinean columnas, y a este tamaño y sola lo único que hacen es dejar los
  /// dígitos sueltos unos de otros.
  static const reportHeroSize = 42.0;
  static const reportHeroGap = 6.0;
  static const reportFigureSize = 15.0;

  /// La barra enfrentada: lo que cada uno consumió, repartido de un borde al
  /// otro. Delgada, que es lo que la hace una barra de datos y no un bloque
  /// de color, y con el hueco del fondo entre los dos tramos en vez de un
  /// borde alrededor de cada uno.
  static const reportBarHeight = 14.0;
  static const reportBarRadius = 4.0;
  static const reportBarGap = 2.0;
  static const reportBarLabelGap = 10.0;

  /// La gráfica de lo que duró cada turno. El alto no cuenta las etiquetas del
  /// eje: se suman aparte, porque una caja de alto fijo que no las incluya las
  /// recorta.
  static const reportChartHeight = 124.0;
  static const reportChartAxisBand = 16.0;
  static const reportChartLabelSize = 10.0;
  static const reportChartLineWidth = 2.0;

  /// La marca del turno más largo de cada jugador, que es la única que se
  /// señala: un punto en cada dato sería un número en cada dato.
  static const reportChartPeakRadius = 4.0;
  static const reportChartPeakRing = 2.0;

  /// La retícula va por detrás y en un solo tono: line continua y fina, nunca
  /// discontinua, que se lee como un umbral y aquí no lo hay.
  static const reportGridWidth = 1.0;
  static const reportGridOpacity = 0.16;
  static const reportChartGap = 10.0;

  /// La media de duración de turno de cada jugador, en su color y de trazo
  /// discontinuo.
  ///
  /// Discontinua a propósito, que es justo lo contrario de lo que se le pide
  /// a la retícula: rayar la retícula está mal porque la hace parecer un
  /// umbral que no es, y esto sí es un umbral. Es la convención de una línea
  /// de referencia, y por eso se distingue de la serie sin necesitar otro
  /// color.
  ///
  /// Más fina y más apagada que la línea del jugador: acompaña a su serie, y
  /// al mismo peso competirían dos líneas del mismo color por la misma
  /// lectura.
  static const reportAverageWidth = 1.0;
  static const reportAverageOpacity = 0.7;
  static const reportAverageDash = 4.0;
  static const reportAverageDashGap = 3.0;

  /// Lo que tarda el acta en montarse sola al salir: las cifras suben desde
  /// cero, la barra se abre desde el medio y las dos líneas recorren sus
  /// turnos. El partido ha durado una hora y pico y esto son cuatro segundos
  /// y pico.
  ///
  /// Se mira una vez y no se repite: no es un adorno que esté ahí siempre,
  /// es la presentación de un resultado, y una presentación que se entiende
  /// es mejor que una rápida. A la mitad de esto no daba tiempo a leer las
  /// cifras mientras subían ni a seguir las dos líneas dibujándose, que es
  /// justo lo que hay que ver.
  ///
  /// Es lo único que hay que tocar para cambiar el ritmo entero: los tramos
  /// de cada fila son fracciones de esto, así que se estiran con ella.
  ///
  /// Quien tenga las animaciones apagadas en el sistema ve el acta hecha
  /// desde el primer fotograma, dure lo que dure.
  static const reportRevealDuration = Duration(milliseconds: 4400);

  /// Lo que cada fila sube mientras aparece. Poco: lo que tiene que llamar la
  /// atención son las cifras subiendo y las líneas dibujándose, no las filas
  /// desplazándose.
  ///
  /// Sube con `Transform`, que no toca la disposición: las filas ocupan su
  /// sitio desde el principio aunque todavía no se vean, de modo que el acta
  /// no cambia de alto mientras se monta y no se reescala a mitad de camino.
  static const reportRevealRise = 10.0;

  /// Lo que los botones se apartan del acta: son lo único que se pulsa en una
  /// pantalla que por lo demás solo se lee, y además quedan fuera de la foto.
  static const reportButtonGap = 30.0;
  static const reportActionGap = 12.0;
  static const reportButtonIconSize = 18.0;
  static const reportButtonIconGap = 8.0;

  /// Lo que el acta se despega del borde dentro de la foto. La pantalla ya
  /// tiene su propio margen, pero la foto se recorta por donde acaba el acta
  /// y sin esto el texto saldría pegado al canto de la imagen.
  static const reportCaptureInset = 16.0;

  /// A cuántos píxeles por punto se saca la foto del acta. Tres, que es lo
  /// que da una imagen legible al abrirla en un ordenador en vez de una
  /// captura del tamaño de un móvil.
  ///
  /// Se mide sobre el acta ya dispuesta y no sobre lo que se ve: si la
  /// pantalla es corta y el acta se encoge para caber, la foto sale igual de
  /// grande, porque lo que encoge es la pintura y no la disposición.
  static const reportCapturePixelRatio = 3.0;

  static const barHeight = 6.0;
  static const barWidthFactor = 0.74;

  /// La brasa de la barra, en la cabeza de lo que queda: la barra es una mecha
  /// que se consume, y esto es el punto por donde arde.
  ///
  /// Se derrama fuera de la barra en vez de aclararla por dentro: la barra de
  /// turno ya es de este mismo blanco, y por dentro no se veía nada.
  ///
  /// Va corta y concentrada a propósito. Un halo ancho se lee como un foco
  /// encendido detrás de la barra; lo que tiene que parecer es un punto que
  /// quema, y para eso el brillo tiene que caer deprisa desde la cabeza.
  ///
  /// Un segundo por ciclo, que es más lento de lo que parpadea una llama de
  /// verdad. Se eligió mirando los tres en el móvil: a esta altura, lo más
  /// rápido se lee como un parpadeo nervioso al lado de los relojes, y un
  /// segundo además hace de tictac, de modo que el adorno acaba diciendo algo.
  static const barGlowDuration = Duration(seconds: 1);

  /// No baja de aquí: la brasa se atenúa, pero no se apaga a medias. Por
  /// debajo, el punto desaparecía de vista en la mitad floja del ciclo y lo
  /// que se veía era un intermitente.
  static const barGlowMinAlpha = 0.65;
  static const barGlowMaxAlpha = 1.0;

  /// En veces el grosor de la barra, y no en píxeles: en una pantalla corta la
  /// barra encoge, y una brasa a medida fija se derramaría fuera de ella.
  static const barGlowBlurFactor = 0.9;
  static const barGlowSpreadFactor = 0.1;

  /// El hueco que comparten la barra y el nombre del reloj de tiempo extra.
  /// Lo manda el texto, que es el más alto de los dos: con la altura de la
  /// barra el nombre saldría partido.
  static const barSlotHeight = 16.0;

  /// El hueco del nombre que va encima del turno. Se reserva también con el
  /// partido empezado, cuando no hay nombre que pintar.
  static const labelSlotHeight = 16.0;

  /// Los dos nombres de reloj, el del turno y el del tiempo extra.
  static const clockLabelSize = 11.0;

  /// Lo que separa cada nombre del reloj que nombra. El mismo para los dos: el
  /// de turno quedaba pegado al suyo y el de tiempo extra suelto entre ambos,
  /// y a distancias distintas no parecían el mismo tipo de etiqueta.
  static const labelToClockGap = 8.0;

  /// Lo que baja el reloj de turno hasta el hueco de debajo, el que comparten
  /// la barra y el nombre del tiempo extra. Mayor que [labelToClockGap] a
  /// propósito: así el nombre queda más cerca del reloj que nombra, el de
  /// abajo, que del que tiene encima.
  static const clockToSlotGap = 18.0;

  /// La invitación a empezar. Por encima de los nombres de reloj y de la pista
  /// de renombrar: es lo único que hay que hacer en esta pantalla, y con su
  /// tamaño no se distinguía de una etiqueta más.
  static const startHintSize = 14.0;

  /// El escudo de la liga, en el centro del campo y solo antes de empezar. Va
  /// a plena opacidad: sus colores son los suyos, y apagarlos no lo vuelve
  /// discreto, lo vuelve deslavado.
  static const leagueLogoSize = 96.0;

  /// La presentación del escudo, en dos tiempos: el cometa recorre el contorno
  /// y, al cerrarlo, entra el escudo mientras el trazo se apaga. Una sola vez,
  /// al abrir la pantalla.
  ///
  /// El cometa manda: hasta que no cierra la silueta no entra el escudo.
  static const logoTraceDuration = Duration(milliseconds: 1500);
  static const logoSettleDuration = Duration(milliseconds: 700);

  /// Lo que mide la cabeza brillante, en píxeles de contorno recorrido, y el
  /// grosor de cada parte del trazo.
  static const logoRevealTailLength = 26.0;
  static const logoRevealHeadWidth = 2.5;
  static const logoRevealTrailWidth = 1.5;
  static const logoRevealTrailAlpha = 0.55;

  /// Lo que un reloj ocupa de alto con un cuerpo de letra dado. Las cifras se
  /// piden con 0,95, y la fuente redondea esa caja hacia arriba: contarla
  /// justa deja la columna unos pocos píxeles por encima de lo que cabe.
  static const _clockLineHeight = 1.05;

  /// Lo que ocupa de alto una línea de texto normal, en veces su cuerpo.
  /// Generoso a propósito: aquí no se mide una fuente, se reparte una pantalla,
  /// y pasarse de largo solo encoge un poco de más.
  static const _textLineHeight = 1.4;

  /// Lo que el reloj de turno ocupa de ancho, en veces su cuerpo de letra. Son
  /// los cinco caracteres de "04:00" a la anchura que Roboto le da a cada uno,
  /// menos lo que les quita el espaciado negativo entre letras.
  ///
  /// El ancho cuenta tanto como el alto: en una pantalla estrecha el reloj no
  /// cabía de largo. Aquí es una estimación, y solo sirve para encoger a
  /// tiempo: lo que garantiza que la cifra cabe es el FittedBox que la envuelve,
  /// porque la anchura real depende de la fuente que ponga cada aparato.
  static const _clockWidthFactor = 3.0;

  /// Lo que la mitad pide de alto si nadie la aprieta. Se calcula con el turno
  /// entero, que es el estado alto: con el turno agotado el reloj de arriba
  /// encoge más de lo que crece el de abajo.
  ///
  /// La suma repite, en el mismo orden, lo que `PlayerHalf` apila en su
  /// columna. Quien añada una fila allí tiene que añadirla también aquí, o la
  /// mitad pedirá menos alto del que ocupa. Es una estimación y no una medida:
  /// lo que la respalda es el FittedBox de los relojes, que encoge de verdad
  /// cuando esta cuenta se queda corta.
  static const naturalHalfHeight =
      nameSize * _textLineHeight +
      _nameVerticalPadding * 2 +
      labelSlotHeight +
      labelToClockGap +
      turnSize * _clockLineHeight +
      clockToSlotGap +
      barSlotHeight +
      labelToClockGap +
      reserveSize * _clockLineHeight +
      startHintSize * _textLineHeight +
      _startHintVerticalPadding * 2;

  /// Lo que la mitad pide de ancho: el reloj de turno, que es el más largo.
  ///
  /// Las dos medidas son de puertas adentro de la tarjeta, que es donde mide
  /// el LayoutBuilder: los márgenes ya se han descontado antes de llegar aquí.
  static const naturalHalfWidth = turnSize * _clockWidthFactor;

  static const _nameVerticalPadding = 8.0;
  static const _nameHorizontalPadding = 24.0;
  static const _startHintVerticalPadding = 14.0;

  /// Las medidas de la mitad para la caja que le ha tocado. Con sitio de sobra
  /// devuelve las de siempre; apretada, todas encogen a la vez y en la misma
  /// proporción, de modo que la mitad se lee igual y solo cabe más pequeña.
  ///
  /// Encoge todo junto y no los huecos primero: apretar los huecos deja los
  /// números pegados unos a otros, y lo que hace legible un cronómetro de
  /// reojo es tanto el tamaño de la cifra como el aire que la rodea.
  static ClockMetrics metricsFor(Size available) {
    final factor = math.min(
      available.height / naturalHalfHeight,
      available.width / naturalHalfWidth,
    );
    if (factor >= 1) return const ClockMetrics._full();
    return ClockMetrics._scaled(factor);
  }
}

/// Las medidas de una mitad, ya resueltas para la caja que tiene. Existe para
/// que la mitad no tenga que saber si la pantalla la está apretando: pide sus
/// medidas y pinta con ellas.
class ClockMetrics {
  const ClockMetrics._full() : scale = 1;

  const ClockMetrics._scaled(this.scale);

  /// Lo que se ha encogido, entre cero y uno. Uno es la pantalla normal.
  final double scale;

  double get turnSize => ClockTheme.turnSize * scale;
  double get turnSizeSpent => ClockTheme.turnSizeSpent * scale;
  double get reserveSize => ClockTheme.reserveSize * scale;
  double get reserveSizeSpent => ClockTheme.reserveSizeSpent * scale;
  double get nameSize => ClockTheme.nameSize * scale;
  double get renameIconSize => ClockTheme.renameIconSize * scale;
  double get renameHintSize => ClockTheme.renameHintSize * scale;
  double get clockLabelSize => ClockTheme.clockLabelSize * scale;
  double get startHintSize => ClockTheme.startHintSize * scale;
  double get barHeight => ClockTheme.barHeight * scale;
  double get labelSlotHeight => ClockTheme.labelSlotHeight * scale;
  double get barSlotHeight => ClockTheme.barSlotHeight * scale;
  double get labelToClockGap => ClockTheme.labelToClockGap * scale;
  double get clockToSlotGap => ClockTheme.clockToSlotGap * scale;

  double get nameVerticalPadding => ClockTheme._nameVerticalPadding * scale;
  double get nameHorizontalPadding =>
      ClockTheme._nameHorizontalPadding * scale;
  double get startHintVerticalPadding =>
      ClockTheme._startHintVerticalPadding * scale;
}
