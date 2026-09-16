import CoreHaptics
import Flutter
import UIKit

private let vibrationChannelName = "com.ares.bloodbowl.turnover/vibration"

/// Las tres intensidades del dominio traducidas a lo que entiende el Taptic
/// Engine. En iOS no hay acceso publico al motor: Core Haptics es la via, y su
/// intensidad va de 0 a 1. La dureza sube con ella para que el aviso mas grave
/// se note seco y no como un zumbido largo.
///
/// Un solo golpe por aviso, al principio y nada mas, por lo mismo que en
/// Android: seguir la forma de la bocina obliga a elegir entre vibrar cuatro
/// segundos y medio o quedarse desincronizado, y ninguna de las dos sirve. Lo
/// que coincide es la entrada.
///
/// Aqui el motor es lineal y responde a la intensidad tal cual se pide, asi que
/// no hacen falta las amplitudes altas que necesita un motor de masa giratoria.
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

  /// Lo que dura el golpe, en segundos. Es lo que distingue un nivel de otro
  /// junto con la intensidad.
  var duration: TimeInterval {
    switch self {
    case .soft: return 0.07
    case .strong: return 0.15
    case .strongest: return 0.30
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
      binaryMessenger: engineBridge.applicationBinaryMessenger
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
        relativeTime: 0,
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
