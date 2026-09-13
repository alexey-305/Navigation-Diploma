import RealmSwift

/// Плоское представление категории для View
struct CategoryItem {
    let name: String
    let quotesCount: Int
}

final class CategoriesViewModel {
    
    private(set) var categories: [CategoryItem] = []
    
    var onCategoriesChanged: (() -> Void)?
    
    private let realmService: RealmService
    private var results: Results<Category>?
    private var notificationToken: NotificationToken?
    
    init(realmService: RealmService = .shared) {
        self.realmService = realmService
    }
    
    func loadCategories() {
        results = realmService.getAllCategories()
        
        notificationToken = results?.observe { [weak self] _ in
            self?.refreshItems()
        }
        
        refreshItems()
    }
    
    private func refreshItems() {
        categories = results?.map { CategoryItem(name: $0.name, quotesCount: $0.quotes.count) } ?? []
        onCategoriesChanged?()
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}
