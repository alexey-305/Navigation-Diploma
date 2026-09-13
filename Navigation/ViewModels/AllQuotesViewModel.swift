import RealmSwift

/// Плоское представление цитаты для View — без прямой зависимости от Realm.Object
struct QuoteItem {
    let text: String
}

final class AllQuotesViewModel {
    
    private(set) var quotes: [QuoteItem] = []
    
    /// Вызывается при любом изменении данных — как при первой загрузке, так и при
    /// изменениях в Realm (реактивно, через Results.observe)
    var onQuotesChanged: (() -> Void)?
    
    private let realmService: RealmService
    private var results: Results<Quote>?
    private var notificationToken: NotificationToken?
    
    init(realmService: RealmService = .shared) {
        self.realmService = realmService
    }
    
    func loadQuotes() {
        results = realmService.getAllQuotes()
        
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
