import Foundation
import FirebaseAuth

enum LoginViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

enum LoginViewInput {
    case loginButtonDidTap(email: String, password: String)
}

final class LoginViewModel {
    
    private(set) var state: LoginViewState = .idle {
        didSet { onStateChanged?(state) }
    }
    
    var onStateChanged: ((LoginViewState) -> Void)?
    
    private let checkerService: CheckerServiceProtocol
    
    init(checkerService: CheckerServiceProtocol = CheckerService()) {
        self.checkerService = checkerService
    }
    
    func updateState(_ input: LoginViewInput) {
        switch input {
        case .loginButtonDidTap(let email, let password):
            handleLoginButtonTap(email: email, password: password)
        }
    }
    
    private func handleLoginButtonTap(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            state = .error("Пожалуйста, заполните все поля")
            return
        }
        
        guard email.contains("@") else {
            state = .error("Введите корректный email")
            return
        }
        
        guard password.count >= 6 else {
            state = .error("Пароль должен быть не менее 6 символов")
            return
        }
        
        state = .loading
        
        checkerService.checkCredentials(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.state = .success
            case .failure(let error as NSError):
                if error.code == AuthErrorCode.userNotFound.rawValue {
                    // Пользователя ещё нет — регистрируем автоматически, как и в прежнем LoginInspector
                    self.signUp(email: email, password: password)
                } else {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func signUp(email: String, password: String) {
        checkerService.signUp(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.state = .success
            case .failure(let error):
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
