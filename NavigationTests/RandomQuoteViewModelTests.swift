import XCTest
@testable import Navigation

final class APIServiceMock: APIServiceProtocol {
    var result: Result<ChuckNorrisQuote, Error> = .success(
        ChuckNorrisQuote(value: "Test quote", category: "test")
    )
    
    func fetchRandomQuote(completion: @escaping (Result<ChuckNorrisQuote, Error>) -> Void) {
        completion(result)
    }
}

final class QuoteSavingMock: QuoteSaving {
    private(set) var savedTexts: [String] = []
    
    func saveQuote(text: String, category: String) {
        savedTexts.append(text)
    }
}

final class QuoteCachingMock: QuoteCaching {
    var cachedValue: String?
    private(set) var didCache = false
    
    func cacheQuote(value: String, category: String?) {
        didCache = true
        cachedValue = value
    }
    
    func lastCachedQuoteValue() -> String? {
        return cachedValue
    }
}

final class RandomQuoteViewModelTests: XCTestCase {
    
    private var apiServiceMock: APIServiceMock!
    private var quoteSavingMock: QuoteSavingMock!
    private var quoteCachingMock: QuoteCachingMock!
    private var sut: RandomQuoteViewModel!
    
    override func setUp() {
        super.setUp()
        apiServiceMock = APIServiceMock()
        quoteSavingMock = QuoteSavingMock()
        quoteCachingMock = QuoteCachingMock()
        sut = RandomQuoteViewModel(
            apiService: apiServiceMock,
            realmService: quoteSavingMock,
            quoteCache: quoteCachingMock
        )
    }
    
    override func tearDown() {
        apiServiceMock = nil
        quoteSavingMock = nil
        quoteCachingMock = nil
        sut = nil
        super.tearDown()
    }
    
    /// Успешный сетевой ответ — цитата сохраняется в Realm, кешируется в CoreData,
    /// state переходит в .loaded
    func test_loadRandomQuote_success_savesAndCachesQuote() {
        apiServiceMock.result = .success(ChuckNorrisQuote(value: "Chuck Norris counts to infinity twice", category: "facts"))
        var receivedState: RandomQuoteViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        sut.loadRandomQuote()
        
        XCTAssertEqual(receivedState, .loaded(text: "Chuck Norris counts to infinity twice"))
        XCTAssertEqual(quoteSavingMock.savedTexts, ["Chuck Norris counts to infinity twice"])
        XCTAssertTrue(quoteCachingMock.didCache)
    }
    
    /// Сети нет, но есть закешированная цитата — приложение остаётся полезным офлайн,
    /// вместо простого показа ошибки
    func test_loadRandomQuote_networkFailure_withCache_fallsBackToCachedQuote() {
        struct StubError: LocalizedError {
            var errorDescription: String? { "The Internet connection appears to be offline." }
        }
        apiServiceMock.result = .failure(StubError())
        quoteCachingMock.cachedValue = "Previously cached quote"
        var receivedState: RandomQuoteViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        sut.loadRandomQuote()
        
        XCTAssertEqual(receivedState, .loadedFromCache(text: "Previously cached quote"))
        XCTAssertTrue(quoteSavingMock.savedTexts.isEmpty, "При ошибке сети ничего не должно сохраняться в Realm")
    }
    
    /// Сети нет, и кеш пуст (первый запуск офлайн) — честно показываем ошибку
    func test_loadRandomQuote_networkFailure_noCache_showsError() {
        struct StubError: LocalizedError {
            var errorDescription: String? { "No connection" }
        }
        apiServiceMock.result = .failure(StubError())
        var receivedState: RandomQuoteViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        sut.loadRandomQuote()
        
        if case .failed = receivedState {
            // ok
        } else {
            XCTFail("Expected .failed state, got \(String(describing: receivedState))")
        }
    }
}
