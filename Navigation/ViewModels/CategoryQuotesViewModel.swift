import RealmSwift

final class CategoryQuotesViewModel {
    
    let categoryName: String
    
    private(set) var quotes: [QuoteItem] = []
    
    var onQuotesChanged: (() -> Void)?
    
    private let realmService: RealmService
    private var results: Results<Quote>?
    private var notificationToken: NotificationToken?
    
    init(categoryName: String, realmService: RealmService = .shared) {
        self.categoryName = categoryName
        self.realmService = realmService
    }
    
    func loadQuotes() {
        results = realmService.getQuotes(for: categoryName)
        
        notificationToken = results?.observe { [weak self] _ in
            self?.refreshItems()
        }
        
        refreshItems()
    }
    
    private func refreshItems() {
        quotes = results?.map { QuoteItem(text: $0.text) } ?? []
        onQuotesChanged?()
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}
