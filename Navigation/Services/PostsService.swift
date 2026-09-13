import UIKit

/// Абстракция над хранилищем постов, чтобы FeedViewModel не знал про Realm
/// напрямую и мог быть протестирован через мок
protocol PostsServiceProtocol {
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void)
    func addPost(author: String, description: String, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void)
}

/// Локальное хранилище постов на базе зашифрованного Realm (см. RealmService).
/// Без обращения в сеть — быстро, работает офлайн, ничего не стоит.
final class PostsService: PostsServiceProtocol {
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        RealmService.shared.seedPostsIfNeeded()
        
        guard let objects = RealmService.shared.getAllPosts() else {
            completion(.success([]))
            return
        }
        
        let posts = objects.map { $0.toPost() }
        completion(.success(Array(posts)))
    }
    
    func addPost(author: String, description: String, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        RealmService.shared.savePost(
            author: author,
            description: description,
            imageAssetName: nil,
            imageData: image?.jpegData(compressionQuality: 0.8)
        )
        completion(.success(()))
    }
}

private extension PostObject {
    func toPost() -> Post {
        let resolvedImage: UIImage?
        if let data = imageData {
            resolvedImage = UIImage(data: data)
        } else if let assetName = imageAssetName {
            resolvedImage = UIImage(named: assetName)
        } else {
            resolvedImage = nil
        }
        
        return Post(
            id: id,
            author: author,
            description: postDescription,
            image: resolvedImage,
            likes: likes,
            views: views,
            imageAssetName: imageAssetName
        )
    }
}
