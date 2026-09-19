import Foundation
import RealmSwift

/// Realm-модель профиля пользователя — статус и аватар, привязанные к конкретному
/// Firebase uid. Раньше статус/аватар были одни и те же для всех, кто ни зайдёт
/// в приложение, и не сохранялись между запусками — теперь у каждого свой профиль,
/// который переживает перезапуск.
class UserProfileObject: Object {
    @Persisted(primaryKey: true) var uid: String = ""
    @Persisted var status: String?
    @Persisted var avatarData: Data?
}
