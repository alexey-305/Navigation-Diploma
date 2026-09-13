//
//  LocalAuthorizationService.swift
//  Navigation
//

import LocalAuthentication

final class LocalAuthorizationService {

    // MARK: - Задача 2*: тип доступной биометрии
    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    /// Тип биометрии, доступный на этом устройстве прямо сейчас.
    /// Использует свежий LAContext, чтобы не полагаться на устаревшее состояние.
    var availableBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    // MARK: - Задача 1

    /// Проверяет доступность биометрии и, если она доступна, запускает авторизацию.
    /// - Parameter authorizationFinished: `success` — результат авторизации,
    ///   `error` (Задача 2*) — причина неудачи, если она есть (недоступность биометрии,
    ///   отказ пользователя, блокировка Face ID/Touch ID после нескольких неудачных попыток и т.д.)
    func authorizeIfPossible(_ authorizationFinished: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authorizationFinished(false, error)
            return
        }

        let reason = "Войдите с помощью биометрии"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
            DispatchQueue.main.async {
                authorizationFinished(success, evaluateError)
            }
        }
    }
}
