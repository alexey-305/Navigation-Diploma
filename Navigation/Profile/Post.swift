import UIKit

struct Post: Identifiable {
    let id: String
    let author: String
    let description: String
    let image: UIImage?
    let likes: Int
    let views: Int
    /// Имя ассета, если пост создан из Assets.xcassets — нужно только для сохранения
    /// в CoreData (избранное), где картинка хранится как имя, а не как сами данные.
    let imageAssetName: String?
    
    init(
        id: String = UUID().uuidString,
        author: String,
        description: String,
        image: UIImage? = nil,
        likes: Int,
        views: Int,
        imageAssetName: String? = nil
    ) {
        self.id = id
        self.author = author
        self.description = description
        self.image = image
        self.likes = likes
        self.views = views
        self.imageAssetName = imageAssetName
    }
}
