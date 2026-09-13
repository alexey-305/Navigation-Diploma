import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        showInitialScreen()
        
        window.makeKeyAndVisible()
    }
    
    /// Показывает экран логина, если пользователь не авторизован, иначе — основное приложение
    func showInitialScreen() {
        if Auth.auth().currentUser != nil {
            showMainApp()
        } else {
            showLogin()
        }
    }
    
    private func showLogin() {
        let loginVC = LoginViewController()
        loginVC.onLoginSuccess = { [weak self] in
            self?.showMainApp()
        }
        window?.rootViewController = loginVC
    }
    
    private func showMainApp() {
        window?.rootViewController = MainTabBarController()
    }
    
    /// Вызывается из ProfileViewController при нажатии "Выйти"
    func showInitialScreenAfterLogOut() {
        try? Auth.auth().signOut()
        showLogin()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        try? Auth.auth().signOut()
        print("👋 Сцена отключена, пользователь разлогинен")
    }
}
