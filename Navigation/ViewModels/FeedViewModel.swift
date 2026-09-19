import Foundation

enum FeedViewState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
    case alreadyInFavorites
    case addedToFavorites
}

/// Абстракция над CoreDataManager, чтобы во ViewModel не было прямой зависимости
/// от CoreData и её можно было подменить на фейк в unit-тестах
protocol FavoritesStoring {
    func isPostAlreadySaved(id: String) -> Bool
    func savePost(id: String, title: String, text: String, author: String, likes: Int, imageName: String?)
}

extension CoreDataManager: FavoritesStoring {}

/// Абстракция над LikesStore — какие посты текущий пользователь уже лайкнул
protocol LikesStoring {
    func isLiked(postId: String) -> Bool
    @discardableResult
    func markLiked(postId: String) -> Bool
}

extension LikesStore: LikesStoring {}

final class FeedViewModel {
    
    private(set) var posts: [Post] = []
    
    private(set) var state: FeedViewState = .idle {
        didSet { onStateChanged?(state) }
    }
    
    var onStateChanged: ((FeedViewState) -> Void)?
    
    private let favoritesStore: FavoritesStoring
    private let postsService: PostsServiceProtocol
    private let likesStore: LikesStoring
    
    init(
        favoritesStore: FavoritesStoring = CoreDataManager.shared,
        postsService: PostsServiceProtocol = PostsService(),
        likesStore: LikesStoring = LikesStore.shared
    ) {
        self.favoritesStore = favoritesStore
        self.postsService = postsService
        self.likesStore = likesStore
    }
    
    /// Загружает ленту постов из локального хранилища (Realm)
    func loadPosts() {
        state = .loading
        
        postsService.fetchPosts { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let posts):
                self.posts = posts
                self.state = .loaded
            case .failure(let error):
                self.state = .failed(error.localizedDescription)
            }
        }
    }
    
    /// Пытается сохранить пост по индексу в избранное.
    /// Если пост уже сохранён — переводит state в .alreadyInFavorites, иначе сохраняет и переводит в .addedToFavorites
    func addToFavorites(at index: Int) {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]
        
        if favoritesStore.isPostAlreadySaved(id: post.id) {
            state = .alreadyInFavorites
            return
        }
        
        favoritesStore.savePost(
            id: post.id,
            title: post.description,
            text: post.description,
            author: post.author,
            likes: post.likes,
            imageName: post.imageAssetName
        )
        state = .addedToFavorites
    }
    
    func isPostLiked(at index: Int) -> Bool {
        guard posts.indices.contains(index) else { return false }
        return likesStore.isLiked(postId: posts[index].id)
    }
    
    /// Ставит лайк посту по индексу — не более одного раза на пользователя
    /// (повторный тап по уже лайкнутому посту ничего не делает)
    func toggleLike(at index: Int) {
        guard posts.indices.contains(index) else { return }
        let post = posts[index]
        
        guard likesStore.markLiked(postId: post.id) else { return }
        
        postsService.likePost(id: post.id) { [weak self] _ in
            guard let self = self else { return }
            
            let updatedPost = Post(
                id: post.id,
                author: post.author,
                description: post.description,
                image: post.image,
                likes: post.likes + 1,
                views: post.views,
                imageAssetName: post.imageAssetName
            )
            self.posts[index] = updatedPost
            self.state = .loaded
        }
    }
}
