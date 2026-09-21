# Ficha de App Store (en-US)

La misma ficha que `../es-ES/ficha.md`, en inglés. Se pega tal cual en App Store
Connect, en el idioma English (U.S.).

Los términos visibles son los de la aplicación en inglés, que están en
`lib/l10n/app_en.arb`. La descripción sale de la de Play en inglés,
`../../play-store/en-US/ficha.md`, con el mismo cambio que en castellano: donde
se habla del volumen del aparato, `phone` pasa a `iPhone`.

Lo propio de App Store son el subtítulo, el texto promocional y las palabras
clave, que Play no tiene.

## Dónde no entra la marca

Lo mismo que en castellano, y por lo mismo: App Store indexa el nombre, el
subtítulo y las palabras clave, así que `Blood Bowl` aparece una sola vez en
toda la ficha, en la descripción y con su aviso al final (ADR-0007).

## App name

Límite: 30 caracteres. Ocupa 9.

```
Turnover!
```

## Subtitle

Límite: 30 caracteres. Ocupa 26.

```
Turn timer for board games
```

El castellano gasta los 30 justos y el inglés se queda en 26. No se rellena por
rellenar: lo que sobra no da ninguna búsqueda que las palabras clave no den
mejor.

## Promotional text

Límite: 170 caracteres. Ocupa 158.

```
Time both players, keep the turn count, and finish on a match report you can share. No accounts, no network, no ads. Open it and play: one tap ends your turn.
```

Este campo se cambia sin publicar una versión nueva, al revés que la
descripción.

## Description

Límite: 4000 caracteres. Ocupa 3619.

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
strength, and they respect the iPhone's volume and settings.

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

## Keywords

Límite: 100 caracteres, separadas por comas. Ocupa 85.

```
stopwatch,clock,chess,tabletop,wargame,rpg,dice,referee,report,miniatures,two players
```

Las mismas reglas que en castellano: sin espacios detrás de las comas, sin
repetir lo que ya está en el nombre ni en el subtítulo (`turn`, `timer`, `board`
y `games` ya están indexados) y sin ninguna marca.

## App Review notes

```
The app is a timer for two-player board game matches. No account, no demo user
and no connection are needed: open it and it works.

HOW TO TRY IT

1. On opening you see two facing halves, one per player. The top half is rotated
   180 degrees on purpose: both players look at the same iPhone from opposite
   sides of the table.
2. A tap on either half starts the match.
3. Every tap after that hands the turn to the other player. Each player carries
   their own turn count next to their clock, from 1 to 16.
4. The centre pause button covers the screen with an overlay, and the reset
   button takes the match back to the start.
5. The pause overlay carries a Time-Out button. Time-Out is a kick-off result of
   the board game, declared by the players by hand: it moves both turn counts by
   one, and it asks which way before doing it.
6. The gear opens the settings, where turn time, extra time and the two early
   warnings are set.

To reach the end of a match without waiting: in the settings, leave turn time and
extra time at their lowest values and play a few turns. Passing the last turn
brings up the match report, which sums up both players' time and can be shared as
an image through the system share sheet.

ABOUT THE TRADEMARK NAMED IN THE DESCRIPTION

The description names Blood Bowl once, to say which game the app is built for.
This is nominative use: the app is a table accessory and reproduces none of the
game's content, rules, graphic marks or proper names. It does not appear in the
app name, the subtitle or the keywords. The description closes with a notice that
the trademark belongs to Games Workshop Limited and that the app is neither
official nor connected to them.

DATA

No data is collected and there is no internet connection at all. The only things
stored are the times and one player's name, in the device's local storage.

Sharing the match report does not change that: the app hands an image to the
system share sheet and neither picks its destination nor keeps a copy.

Those settings are included in iCloud backup, like those of any app using the
system's standard storage. That is not data collection: they never leave the
device on the app's initiative and we never receive them.

IPHONE ONLY

The app ships for iPhone only. The layout reads in portrait and only in portrait,
because the two players sit facing each other and each half reads from its own
side. On iPad the app would share the screen and would not control rotation,
which is incompatible with that.
```

## Category, age rating, export compliance, privacy

No son campos por idioma: se responden una vez para toda la aplicación y están
en `../es-ES/ficha.md`.

## Previsualizaciones

Todavía no hay, ni en castellano ni en inglés. Están explicadas en
`../previsualizaciones.md`.
