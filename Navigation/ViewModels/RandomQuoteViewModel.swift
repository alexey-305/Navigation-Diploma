import Foundation

enum RandomQuoteViewState: Equatable {
    case idle
    case loading
    case loaded(text: String)
    /// Сети нет — показываем последнюю успешно загруженную цитату из CoreData
    case loadedFromCache(text: String)
    case failed(String)
}

/// Абстракция над сохранением цитаты в Realm — по аналогии с FavoritesStoring
/// в FeedViewModel, чтобы ViewModel был полностью тестируем без реального Realm
protocol QuoteSaving {
    func saveQuote(text: String, category: String)
}

extension RealmService: QuoteSaving {}

/// Абстракция над CoreData-кешем последней цитаты — чтобы ViewModel не был
/// завязан на конкретный CoreDataManager и его можно было подменить в тестах
protocol QuoteCaching {
    func cacheQuote(value: String, category: String?)
    func lastCachedQuoteValue() -> String?
}

extension CoreDataManager: QuoteCaching {
    func lastCachedQuoteValue() -> String? {
        lastCachedQuote()?.value
    }
}

final class RandomQuoteViewModel {
    
    private(set) var state: RandomQuoteViewState = .idle {
        didSet { onStateChanged?(state) }
    }
    
    var onStateChanged: ((RandomQuoteViewState) -> Void)?
    
    private let apiService: APIServiceProtocol
    private let realmService: QuoteSaving
    private let quoteCache: QuoteCaching
    
    init(
        apiService: APIServiceProtocol = APIService(),
        realmService: QuoteSaving = RealmService.shared,
        quoteCache: QuoteCaching = CoreDataManager.shared
    ) {
        self.apiService = apiService
        self.realmService = realmService
        self.quoteCache = quoteCache
    }
    
    /// Загружает случайную цитату через реальный сетевой запрос (URLSession, api.chucknorris.io).
    /// Если сети нет — не просто показывает ошибку, а пытается достать последнюю
    /// успешно загруженную цитату из CoreData-кеша, чтобы приложение оставалось
    /// полезным офлайн (реальный offline-first сценарий, а не имитация сети).
    func loadRandomQuote() {
        state = .loading
        
        apiService.fetchRandomQuote { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let quote):
                    let category = quote.category ?? "random_quote.category.none".localized
                    self.realmService.saveQuote(text: quote.value, category: category)
                    self.quoteCache.cacheQuote(value: quote.value, category: category)
                    self.state = .loaded(text: quote.value)
                    
                case .failure(let error):
                    if let cachedValue = self.quoteCache.lastCachedQuoteValue() {
                        self.state = .loadedFromCache(text: cachedValue)
                    } else {
                        self.state = .failed("random_quote.error.format".localized(error.localizedDescription))
                    }
                }
            }
        }
    }
}
