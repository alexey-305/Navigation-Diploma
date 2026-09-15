import Foundation
import FirebaseAuth

/// Локально запоминает, какие посты текущий пользователь уже лайкнул —
/// чтобы повторный тап не накручивал счётчик бесконечно. Реальная соцсеть
/// хранила бы это в БД привязанным к паре (пользователь, пост); здесь —
/// UserDefaults с ключом на основе uid, этого достаточно для одного устройства.
final class LikesStore {
    
    static let shared = LikesStore()
    
    private init() {}
    
    private var defaultsKey: String {
        "likedPostIDs_\(Auth.auth().currentUser?.uid ?? "anonymous")"
    }
    
    func isLiked(postId: String) -> Bool {
        likedIDs().contains(postId)
    }
    
    /// Возвращает true, если лайк применился впервые (то есть нужно увеличить счётчик)
    @discardableResult
    func markLiked(postId: String) -> Bool {
        var ids = likedIDs()
        guard !ids.contains(postId) else { return false }
        ids.insert(postId)
        UserDefaults.standard.set(Array(ids), forKey: defaultsKey)
        return true
    }
    
    private func likedIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? [])
    }
}
