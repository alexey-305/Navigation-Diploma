import UIKit

class ProfileCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let profileVC = ProfileViewController()
        profileVC.coordinator = self
        navigationController.setViewControllers([profileVC], animated: false)
    }
    
    func showPostDetails(_ post: Post) {
        let postVC = PostViewController()
        postVC.post = post
        navigationController.pushViewController(postVC, animated: true)
    }
}
