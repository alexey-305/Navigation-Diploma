import Foundation

/// Единая точка сборки сервисов и ViewModel.
///
/// До этого сервисы создавались по месту — либо через .shared-синглтоны,
/// либо через дефолтные значения параметров инициализатора, разбросанные
/// по разным экранам (`FeedViewModel(favoritesStore: CoreDataManager.shared, ...)`
/// в одном месте и `LoginViewModel(checkerService: CheckerService())` в другом).
/// Контейнер не меняет сам механизм внедрения зависимостей (по-прежнему
/// initializer injection с дефолтными значениями — простой, идиоматичный для
/// Swift подход без сторонних библиотек), а централизует его: один файл,
/// где видно, какой конкретный сервис стоит за каждым протоколом, и как
/// собирается каждый экран.
final class AppDependencyContainer {
    
    static let shared = AppDependencyContainer()
    
    private init() {}
    
    // MARK: - Сервисы (создаются один раз, переиспользуются)
    
    lazy var postsService: PostsServiceProtocol = PostsService()
    lazy var favoritesStore: FavoritesStoring = CoreDataManager.shared
    lazy var checkerService: CheckerServiceProtocol = CheckerService()
    lazy var apiService: APIServiceProtocol = APIService()
    lazy var quoteSaving: QuoteSaving = RealmService.shared
    lazy var quoteCache: QuoteCaching = CoreDataManager.shared
    lazy var localAuthorizationService = LocalAuthorizationService()
    
    // MARK: - Фабрики ViewModel
    
    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(favoritesStore: favoritesStore, postsService: postsService)
    }
    
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(checkerService: checkerService)
    }
    
    func makeRandomQuoteViewModel() -> RandomQuoteViewModel {
        RandomQuoteViewModel(apiService: apiService, realmService: quoteSaving, quoteCache: quoteCache)
    }
    
    func makeAllQuotesViewModel() -> AllQuotesViewModel {
        AllQuotesViewModel(realmService: .shared)
    }
    
    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel(realmService: .shared)
    }
    
    func makeCategoryQuotesViewModel(categoryName: String) -> CategoryQuotesViewModel {
        CategoryQuotesViewModel(categoryName: categoryName, realmService: .shared)
    }
}
