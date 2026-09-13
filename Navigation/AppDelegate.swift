import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Временно отключаем Analytics
        let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let options = FirebaseOptions(contentsOfFile: filePath)!
        FirebaseApp.configure(options: options)
        
        print("🔥 Firebase сконфигурирован!")
        
        LocalNotificationsService.shared.registerForLatestUpdatesIfPossible()
        
        return true
    }
    
    /// Переключает таббар на вкладку "Лента" — действие по тапу на уведомление о новых обновлениях
    func showFeedTabForLatestUpdates() {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        guard let tabBarController = keyWindow?.rootViewController as? UITabBarController,
              let feedNavIndex = tabBarController.viewControllers?.firstIndex(where: { navController in
                  (navController as? UINavigationController)?.viewControllers.first is FeedViewController
              }) else { return }
        
        tabBarController.selectedIndex = feedNavIndex
    }
}

