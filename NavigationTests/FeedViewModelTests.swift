import XCTest
import UIKit
@testable import Navigation

final class FavoritesStoringMock: FavoritesStoring {
    var isAlreadySaved = false
    private(set) var savedPostIDs: [String] = []
    
    func isPostAlreadySaved(id: String) -> Bool {
        return isAlreadySaved
    }
    
    func savePost(id: String, title: String, text: String, author: String, likes: Int, imageName: String?) {
        savedPostIDs.append(id)
    }
}

/// Мок вместо реального обращения к Realm — возвращает заданный результат синхронно
final class PostsServiceMock: PostsServiceProtocol {
    var result: Result<[Post], Error> = .success([
        Post(author: "Test Author", description: "Test description", likes: 1, views: 2)
    ])
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        completion(result)
    }
    
    func addPost(author: String, description: String, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
    private(set) var likedPostIDs: [String] = []
    
    func likePost(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        likedPostIDs.append(id)
        completion(.success(()))
    }
}

final class LikesStoringMock: LikesStoring {
    private var liked: Set<String> = []
    
    func isLiked(postId: String) -> Bool {
        liked.contains(postId)
    }
    
    @discardableResult
    func markLiked(postId: String) -> Bool {
        guard !liked.contains(postId) else { return false }
        liked.insert(postId)
        return true
    }
}

final class FeedViewModelTests: XCTestCase {
    
    private var favoritesStoreMock: FavoritesStoringMock!
    private var postsServiceMock: PostsServiceMock!
    private var likesStoreMock: LikesStoringMock!
    private var sut: FeedViewModel!
    
    override func setUp() {
        super.setUp()
        favoritesStoreMock = FavoritesStoringMock()
        postsServiceMock = PostsServiceMock()
        likesStoreMock = LikesStoringMock()
        sut = FeedViewModel(favoritesStore: favoritesStoreMock, postsService: postsServiceMock, likesStore: likesStoreMock)
    }
    
    override func tearDown() {
        favoritesStoreMock = nil
        postsServiceMock = nil
        likesStoreMock = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - loadPosts()
    
    func test_loadPosts_populatesPostsAndSetsLoadedState() {
        // given
        var receivedState: FeedViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        // when
        sut.loadPosts()
        
        // then
        XCTAssertFalse(sut.posts.isEmpty)
        XCTAssertEqual(receivedState, .loaded)
    }
    
    func test_loadPosts_serviceFailure_setsFailedStateAndKeepsPostsEmpty() {
        // given
        struct StubError: LocalizedError {
            var errorDescription: String? { "Network unavailable" }
        }
        postsServiceMock.result = .failure(StubError())
        var receivedState: FeedViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        // when
        sut.loadPosts()
        
        // then
        XCTAssertTrue(sut.posts.isEmpty)
        XCTAssertEqual(receivedState, .failed("Network unavailable"))
    }
    
    // MARK: - addToFavorites(at:)
    
    func test_addToFavorites_newPost_savesItAndSetsAddedState() {
        // given
        sut.loadPosts()
        favoritesStoreMock.isAlreadySaved = false
        var receivedState: FeedViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        // when
        sut.addToFavorites(at: 0)
        
        // then
        XCTAssertEqual(favoritesStoreMock.savedPostIDs.count, 1)
        XCTAssertEqual(receivedState, .addedToFavorites)
    }
    
    func test_addToFavorites_postAlreadySaved_doesNotSaveAgainAndSetsAlreadyInFavoritesState() {
        // given
        sut.loadPosts()
        favoritesStoreMock.isAlreadySaved = true
        var receivedState: FeedViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        // when
        sut.addToFavorites(at: 0)
        
        // then
        XCTAssertTrue(favoritesStoreMock.savedPostIDs.isEmpty)
        XCTAssertEqual(receivedState, .alreadyInFavorites)
    }
    
    func test_addToFavorites_invalidIndex_doesNothingAndDoesNotChangeState() {
        // given
        sut.loadPosts()
        var receivedState: FeedViewState?
        sut.onStateChanged = { receivedState = $0 }
        
        // when
        sut.addToFavorites(at: 999)
        
        // then
        XCTAssertTrue(favoritesStoreMock.savedPostIDs.isEmpty)
        XCTAssertNil(receivedState)
    }
    
    func test_toggleLike_incrementsLikesAndCallsService() {
        // given
        sut.loadPosts()
        let originalLikes = sut.posts[0].likes
        let postId = sut.posts[0].id
        
        // when
        sut.toggleLike(at: 0)
        
        // then
        XCTAssertEqual(sut.posts[0].likes, originalLikes + 1)
        XCTAssertEqual(postsServiceMock.likedPostIDs, [postId])
        XCTAssertTrue(sut.isPostLiked(at: 0))
    }
    
    func test_toggleLike_calledTwice_onlyLikesOnce() {
        // given
        sut.loadPosts()
        let originalLikes = sut.posts[0].likes
        
        // when
        sut.toggleLike(at: 0)
        sut.toggleLike(at: 0)
        
        // then
        XCTAssertEqual(sut.posts[0].likes, originalLikes + 1, "Повторный тап не должен увеличивать счётчик ещё раз")
        XCTAssertEqual(postsServiceMock.likedPostIDs.count, 1)
    }
}
