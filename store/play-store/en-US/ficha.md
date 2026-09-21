# Ficha de Play Store (en-US)

La misma ficha que `../es-ES/ficha.md`, en inglés. Se pega tal cual en Play
Console, en el idioma inglés (Estados Unidos).

No es una traducción literal: los términos visibles son los que ya usa la
aplicación en inglés, que están en `lib/l10n/app_en.arb`. Turn time, extra time,
Time-Out, kick-off, match report. Al tocar uno hay que mirar el otro.

La castellana es la maestra. Si cambia un argumento, cambia allí primero.

## App name

Límite: 30 caracteres. Ocupa 9.

```
Turnover!
```

## Short description

Límite: 80 caracteres. Ocupa 66.

```
Turn timer, turn count and match report for turn-based board games
```

Sin la marca, igual que en castellano: el nombre y la descripción breve son los
campos que indexa la tienda (ADR-0007).

## Full description

Límite: 4000 caracteres. Ocupa 3618.

```
Turnover! times a two-player game on a single phone laid on the table. No
accounts, no network, no sign-up: open it and play.

It is built for Blood Bowl matches, where each coach gets a regulation turn and a
pool of extra time for the whole game, but it works for any turn-based board game
played against the clock.

HOW IT WORKS

The screen splits in two, one half per player, and each half reads the right way
up from its own side of the table. Whoever taps their half receives the kick-off
and starts the match. From there on, one tap ends your turn.

THE TWO CLOCKS

Turn time is the regulation time for a single turn, and it restarts every time the
turn changes hands. Four minutes by default.

Extra time is each player's own pool for the whole match. It only goes down, it is
never refilled, and it starts draining the moment the turn clock hits zero. Fifteen
minutes by default.

Once extra time is gone the clock keeps counting into the negative. It stops
nothing: it records how far over each player went.

THE TURN COUNT

Each player carries their turn number next to their clock. The first half runs
from 1 to 8 and the second from 9 to 16, straight through, so the half is there to
be read in the number itself.

Changing halves is not just another turn. The pass that closes the first half
leaves the match paused, which is when sides are swapped and the teams set up
again. The overlay says so, and the same tap that clears any pause clears it.

TIME-OUT

This is the kick-off result that moves the turn count, and the players declare it:
the pause overlay carries its button. Confirm it and both teams move one turn
forward, or one back if the kicking team's counter sits on turn 6, 7 or 8. The app
rolls no dice: it applies the rule when told to, so a half can run seven turns or
nine, exactly as it does on the table.

WARNINGS

Three horns, quiet to loud: a warning before the turn runs out, the turn running
out, and extra time running out. Each one comes with its own vibration at matching
strength, and they respect the phone's volume and settings.

TIMES TO TASTE

Turn time and extra time are set before the match starts, each on its own slider.
The early warnings are two, and they move on the two handles of a single slider:
together they are one warning, apart they are two, and both at zero is no warning
at all. They sound at 55 and 30 seconds by default. Times are agreed with the
clock stopped.

Either player can set their own name with a long press on their half.

THE MATCH REPORT

The match ends on a report of what the clock saw: play time for both players, the
total with the stoppages inside it, a bar splitting that play time between the
two, and a turn-by-turn chart carrying each player's average turn. That is where
you see where the game bogged down.

The report shares as an image through the system share sheet, ready to send to
whoever runs the league.

ALSO

The screen stays awake while a clock runs and is released on pause.

Pausing covers the screen with an overlay that still lets both clocks be read
underneath: you talk the play over and the time stays in sight.

No ads, no in-app purchases and no permissions. The app collects no data and never
connects to the internet.

WHAT IT DOES NOT DO

It keeps no score and records no touchdowns, and it stores no match history, not
even the report: that one is shared there and then, or lost. It is a referee that
measures time, not one that decides anything.

Blood Bowl is a registered trademark of Games Workshop Limited. This app is
unofficial and is not affiliated with, sponsored by or endorsed by Games Workshop.
```

## Category and tags

- Categoría: Tools, que es como se llama en inglés la Herramientas de la ficha
  castellana. No Games, por la misma razón.
- Etiquetas sugeridas: stopwatch, timer, board games, chess clock.

## Contact details

Los mismos que en castellano: no son un campo por idioma.

## Content rating y Data safety

El cuestionario de clasificación y el de seguridad de los datos se responden una
vez para toda la aplicación, no por idioma. Están en `../es-ES/ficha.md` y no se
repiten aquí.
