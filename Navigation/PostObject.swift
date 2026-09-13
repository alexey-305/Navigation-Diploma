import Foundation
import RealmSwift

/// Realm-модель поста — хранится локально, зашифрована тем же ключом, что и цитаты
/// (см. RealmService/KeychainManager). Картинка хранится как Data, если пост создан
/// пользователем, либо как имя ассета, если это один из стартовых постов.
class PostObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var author: String = ""
    @Persisted var postDescription: String = ""
    @Persisted var imageAssetName: String?
    @Persisted var imageData: Data?
    @Persisted var likes: Int = 0
    @Persisted var views: Int = 0
    @Persisted var createdAt: Date = Date()
}
