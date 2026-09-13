import Foundation
import RealmSwift

class Quote: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var text: String = ""
    @Persisted var category: String = ""
    @Persisted var createdAt: Date = Date()
    
    convenience init(text: String, category: String) {
        self.init()
        self.text = text
        self.category = category
    }
}
