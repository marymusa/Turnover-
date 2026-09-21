import CoreHaptics
import Flutter
import UIKit

private let vibrationChannelName = "com.ares.bloodbowl.turnover/vibration"

/// Lo que espera la vibracion antes de arrancar, para salir a la vez que la
/// bocina y no antes.
///
/// `AlertPlayer` lanza las dos a la vez, pero eso es a la vez en el codigo, no
/// en el oido: la vibracion arranca al momento y el sonido pasa por la salida
/// de audio, que tarda. En Android se noto y se corrigio midiendo el aparato;
/// aqui se pone el mismo orden de magnitud, mas corto porque la salida de audio
/// de iOS es bastante mas rapida.
///
/// Sin comprobar en un iPhone de verdad: no hay ninguno a mano. Es lo primero
/// que hay que mirar cuando lo haya.
private let audioLeadIn: TimeInterval = 0.03

/// Las tres intensidades del dominio traducidas a lo que entiende el Taptic
/// Engine. En iOS no hay acceso publico al motor: Core Haptics es la via, y su
/// intensidad va de 0 a 1. La dureza sube con ella para que el aviso mas grave
/// se note seco y no como un zumbido plano.
///
/// Los dos ejes suben juntos, igual que en Android: segundo y medio, tres
/// segundos y cuatro y medio, con intensidad 0,4, 0,7 y 1,0. La version
/// anterior daba golpes de 70, 150 y 300 milisegundos y los probadores decian
/// todos lo mismo, que la vibracion no acompanaba a la bocina ni en lo que
/// duraba ni en la fuerza (ADR-0005).
///
/// El paso de segundo y medio entre niveles es a proposito y es igual entre los
/// tres: lo que tiene que quedar claro al notarla es cual de los tres avisos
/// es. La duracion de la bocina no entra en la cuenta.
///
/// Aqui el motor es lineal y responde a la intensidad tal cual se pide, asi que
/// no hace falta el suelo de amplitud que necesita un motor de masa giratoria.
private enum VibrationLevel: String {
  case soft
  case strong
  case strongest

  var intensity: Float {
    switch self {
    case .soft: return 0.4
    case .strong: return 0.7
    case .strongest: return 1.0
    }
  }

  var sharpness: Float {
    switch self {
    case .soft: return 0.3
    case .strong: return 0.6
    case .strongest: return 1.0
    }
  }

  /// Lo que dura el aviso, en segundos. Es lo que distingue un nivel de otro
  /// junto con la intensidad.
  var duration: TimeInterval {
    switch self {
    case .soft: return 1.5
    case .strong: return 3.0
    case .strongest: return 4.5
    }
  }

  /// El aparato sin Taptic Engine se queda con el generador de impactos, que da
  /// tres pesos y ningun control fino. Es lo que hay, y el aviso sale igual por
  /// el altavoz.
  var fallbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
    switch self {
    case .soft: return .light
    case .strong: return .medium
    case .strongest: return .heavy
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// El motor se guarda entre avisos: arrancarlo en cada bocina mete un retraso
  /// que se nota justo cuando el aviso tiene que ser puntual.
  private var hapticEngine: CHHapticEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: vibrationChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "vibrate" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let name = arguments["level"] as? String,
        let level = VibrationLevel(rawValue: name)
      else {
        result(FlutterError(code: "UNKNOWN_VIBRATION_LEVEL", message: nil, details: nil))
        return
      }
      self?.vibrate(level)
      result(nil)
    }
  }

  private func vibrate(_ level: VibrationLevel) {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
      UIImpactFeedbackGenerator(style: level.fallbackStyle).impactOccurred()
      return
    }

    do {
      let engine = try runningEngine()
      let event = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: level.intensity),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: level.sharpness),
        ],
        relativeTime: audioLeadIn,
        duration: level.duration
      )
      let pattern = try CHHapticPattern(events: [event], parameters: [])
      try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    } catch {
      // Un aviso que no sale no es motivo para tumbar el partido: el reloj
      // sigue corriendo y la bocina suena igual.
      UIImpactFeedbackGenerator(style: level.fallbackStyle).impactOccurred()
    }
  }

  private func runningEngine() throws -> CHHapticEngine {
    if let engine = hapticEngine {
      try engine.start()
      return engine
    }
    let engine = try CHHapticEngine()
    // El sistema para el motor al pasar a segundo plano, y sin esto el primer
    // aviso al volver no se nota.
    engine.resetHandler = { [weak self] in try? self?.hapticEngine?.start() }
    engine.stoppedHandler = { _ in }
    try engine.start()
    hapticEngine = engine
    return engine
  }
}
