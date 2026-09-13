import UIKit

class MainTabBarController: UITabBarController {
    
    // Держим сильную ссылку — у ProfileViewController.coordinator она weak
    private var profileCoordinator: ProfileCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
        setupMoreTabTitle()
    }
    
    private func setupMoreTabTitle() {
        moreNavigationController.tabBarItem.title = "tabbar.more".localized
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.isTranslucent = false
    }
    
    private func setupTabs() {
        // Основные экраны приложения (по духу ВКонтакте): лента и профиль — первые вкладки
        let feedVC = FeedViewController()
        feedVC.tabBarItem = UITabBarItem(
            title: "tabbar.feed".localized,
            image: UIImage(systemName: "newspaper"),
            tag: 0
        )
        let navFeed = UINavigationController(rootViewController: feedVC)
        
        let profileVC = ProfileViewController()
        let navProfile = UINavigationController(rootViewController: profileVC)
        profileCoordinator = ProfileCoordinator(navigationController: navProfile)
        profileVC.coordinator = profileCoordinator
        profileVC.tabBarItem = UITabBarItem(
            title: "tabbar.profile".localized,
            image: UIImage(systemName: "person.circle"),
            tag: 1
        )
        
        let favoritesVC = FavoritesViewController()
        favoritesVC.tabBarItem = UITabBarItem(
            title: "tabbar.favorites".localized,
            image: UIImage(systemName: "heart"),
            tag: 2
        )
        let navFavorites = UINavigationController(rootViewController: favoritesVC)
        
        let mapVC = MapViewController()
        mapVC.tabBarItem = UITabBarItem(
            title: "tabbar.map".localized,
            image: UIImage(systemName: "map"),
            tag: 3
        )
        let navMap = UINavigationController(rootViewController: mapVC)
        
        // Второстепенные экраны (агрегатор цитат из прошлых домашек) — уходят под "Ещё"
        let randomVC = RandomQuoteViewController()
        randomVC.tabBarItem = UITabBarItem(
            title: "tabbar.random".localized,
            image: UIImage(systemName: "quote.bubble"),
            tag: 4
        )
        let navRandom = UINavigationController(rootViewController: randomVC)
        
        let allVC = AllQuotesViewController()
        allVC.tabBarItem = UITabBarItem(
            title: "tabbar.all_quotes".localized,
            image: UIImage(systemName: "list.bullet"),
            tag: 5
        )
        let navAll = UINavigationController(rootViewController: allVC)
        
        let categoriesVC = CategoriesViewController()
        categoriesVC.tabBarItem = UITabBarItem(
            title: "tabbar.categories".localized,
            image: UIImage(systemName: "folder"),
            tag: 6
        )
        let navCategories = UINavigationController(rootViewController: categoriesVC)
        
        viewControllers = [navFeed, navProfile, navFavorites, navMap, navRandom, navAll, navCategories]
    }
}
