package com.ares.bloodbowl.turnover

import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val VIBRATION_CHANNEL = "com.ares.bloodbowl.turnover/vibration"

/** La onda se toca una vez y no vuelve: el aviso acompana a la bocina y acaba
 *  con ella, no se queda repitiendo como una alarma. */
private const val NO_REPEAT = -1

/**
 * Lo que espera la vibracion antes de arrancar, para salir a la vez que la
 * bocina y no antes.
 *
 * `AlertPlayer` lanza las dos a la vez, pero eso es a la vez en el codigo, no
 * en el oido: la vibracion es una llamada al motor y arranca al momento,
 * mientras que el sonido pasa por el SoundPool y por la salida de audio, que
 * tardan. Se notaba, y el aviso salia descuadrado.
 *
 * El numero sale del propio aparato, no de una estimacion: el Mi 9 declara
 * `latency=21 ms` y `measuredWarmup=8 ms` en su mezclador rapido
 * (`dumpsys media.audio_flinger`), y encima de eso el SoundPool tiene que
 * arrancar su voz. Cuarenta y cinco cae dentro de lo que mide el aparato y es
 * lo bastante corto para que pasarse tampoco se note.
 *
 * Es un valor de este aparato y de esta salida de audio: por Bluetooth la
 * latencia es mucho mayor y esto se queda corto. No se corrige por ahora,
 * porque descuadrarse hacia el otro lado con auriculares es lo mismo que habia
 * antes y no hay forma de leer esa latencia sin complicar el adaptador.
 */
private const val AUDIO_LEAD_IN_MILLISECONDS = 45L

/**
 * Las tres intensidades del dominio, traducidas a lo que entiende el motor.
 *
 * Los dos ejes suben juntos: segundo y medio, tres segundos y cuatro y medio de
 * duracion, con amplitud 180, 220 y 255. Los probadores decian todos lo mismo,
 * que la vibracion no acompanaba a la bocina ni en lo que duraba ni en la
 * fuerza; la version anterior daba golpes de 70, 180 y 330 milisegundos y se
 * perdian debajo de un sonido de varios segundos (ADR-0005).
 *
 * El paso de segundo y medio entre niveles es a proposito y es igual entre los
 * tres: lo que tiene que quedar claro al notarla es cual de los tres avisos es,
 * y un salto constante y grande se lee sin pensar. La duracion de la bocina no
 * entra en la cuenta; son dos escalas distintas.
 *
 * El suelo de 180 no se baja. Muchos moviles, este Mi 9 entre ellos, llevan un
 * motor de masa giratoria y no uno lineal: tiene inercia, tarda en arrancar, y
 * por debajo de unos 180 de amplitud no llega a moverse lo bastante para
 * notarse. Las amplitudes bajas que recomienda Android son para motores
 * lineales. Por eso los tres niveles reparten el tramo que si se nota, de 180
 * a 255, en vez de repartir la escala entera de 0 a 255.
 *
 * La onda empieza y acaba en cero. Al principio, para esperar a que salga el
 * sonido; al final, para que el driver frene y el aviso corte limpio en vez de
 * dejar al motor zumbando cuando termina.
 */
private enum class VibrationLevel(
    val timings: LongArray,
    val amplitudes: IntArray,
) {
    SOFT(longArrayOf(AUDIO_LEAD_IN_MILLISECONDS, 1500, 40), intArrayOf(0, 180, 0)),
    STRONG(longArrayOf(AUDIO_LEAD_IN_MILLISECONDS, 3000, 40), intArrayOf(0, 220, 0)),
    STRONGEST(longArrayOf(AUDIO_LEAD_IN_MILLISECONDS, 4500, 40), intArrayOf(0, 255, 0));

    companion object {
        fun from(name: String?) = when (name) {
            "soft" -> SOFT
            "strong" -> STRONG
            "strongest" -> STRONGEST
            else -> null
        }
    }

    /**
     * Lo que vibra de verdad, sin contar la espera del principio ni el tramo
     * de frenado: es lo que le toca al motor que no sabe graduar la fuerza, que
     * solo sabe encenderse durante un rato.
     */
    val activeMilliseconds: Long get() = timings[1]
}

/**
 * `USAGE_NOTIFICATION` y no `USAGE_ALARM`: el canal de alarma esta exento de la
 * configuracion de vibracion del jugador para que un despertador suene pase lo
 * que pase, y aqui no hay nada que imponer por encima del movil (ADR-0005).
 */
private val alertAttributes: AudioAttributes = AudioAttributes.Builder()
    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
    .build()

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VIBRATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "vibrate") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val level = VibrationLevel.from(call.argument<String>("level"))
            if (level == null) {
                result.error("UNKNOWN_VIBRATION_LEVEL", null, null)
                return@setMethodCallHandler
            }
            vibrate(level)
            result.success(null)
        }
    }

    private fun vibrate(level: VibrationLevel) {
        val vibrator = vibrator() ?: return
        if (!vibrator.hasVibrator()) return

        // Sin control de amplitud el motor solo sabe encenderse y apagarse, asi
        // que ahi la intensidad la lleva la duracion sola: los tres niveles se
        // distinguen por el segundo y medio, los tres o los cuatro y medio que
        // dura cada uno y nada mas. La onda sin amplitudes alterna apagado y
        // encendido, asi que el primer tramo es la misma espera que en la otra
        // rama y el segundo lo que vibra.
        val effect = if (vibrator.hasAmplitudeControl()) {
            VibrationEffect.createWaveform(level.timings, level.amplitudes, NO_REPEAT)
        } else {
            VibrationEffect.createWaveform(
                longArrayOf(AUDIO_LEAD_IN_MILLISECONDS, level.activeMilliseconds),
                NO_REPEAT,
            )
        }
        vibrator.vibrate(effect, alertAttributes)
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(VibratorManager::class.java)
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }
}
