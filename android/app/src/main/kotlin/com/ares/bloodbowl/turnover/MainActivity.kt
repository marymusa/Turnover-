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

/** La onda se toca una vez y no vuelve: el aviso es un golpe, no una alarma. */
private const val NO_REPEAT = -1

/**
 * Las tres intensidades del dominio, traducidas a lo que entiende el motor.
 *
 * Cada una es una onda que acaba en cero, para que el driver frene y el aviso
 * corte limpio en vez de dejar al motor zumbando.
 *
 * Lo que separa un nivel de otro es sobre todo cuanto dura, no con cuanta
 * fuerza sale. Muchos moviles, este Mi 9 entre ellos, llevan un motor de masa
 * giratoria y no uno lineal: tiene inercia, tarda en arrancar, y por debajo de
 * unos 180 de amplitud no llega a moverse lo bastante para notarse. Las
 * amplitudes bajas y los tramos muy cortos que recomienda Android son para
 * motores lineales. El propio tono de llamada del sistema usa 255 en los
 * golpes cortos, y es la referencia de lo que aqui se nota.
 *
 * Un solo golpe por aviso, al principio y nada mas. Se probo seguir la forma de
 * cada bocina, con sus pitidos y sus silencios, y no encaja: la bocina mas larga
 * dura 4,6 segundos, y recortar los silencios para no estar vibrando todo ese
 * rato deja la vibracion adelantada respecto al sonido desde el primer golpe. O
 * se sigue el sonido entero o no se sigue; y seguirlo entero es tener el movil
 * zumbando cuatro segundos y medio, que ademas hace ruido y tapa la bocina.
 *
 * Asi que lo que coincide es la entrada, que es lo que se nota: los dos salen a
 * la vez porque `AlertPlayer` los lanza juntos. Lo que separa un nivel de otro es
 * cuanto dura el golpe.
 */
private enum class VibrationLevel(
    val timings: LongArray,
    val amplitudes: IntArray,
) {
    SOFT(longArrayOf(40, 30), intArrayOf(200, 0)),
    STRONG(longArrayOf(30, 120, 30), intArrayOf(180, 255, 0)),
    STRONGEST(longArrayOf(30, 260, 40), intArrayOf(180, 255, 0));

    companion object {
        fun from(name: String?) = when (name) {
            "soft" -> SOFT
            "strong" -> STRONG
            "strongest" -> STRONGEST
            else -> null
        }
    }

    /** Lo que dura entera, para el motor que no sabe graduar la fuerza. */
    val totalMilliseconds: Long get() = timings.sum()
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
        // que ahi la intensidad la lleva la duracion sola y la rampa no pinta
        // nada.
        val effect = if (vibrator.hasAmplitudeControl()) {
            VibrationEffect.createWaveform(level.timings, level.amplitudes, NO_REPEAT)
        } else {
            VibrationEffect.createOneShot(
                level.totalMilliseconds,
                VibrationEffect.DEFAULT_AMPLITUDE,
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
