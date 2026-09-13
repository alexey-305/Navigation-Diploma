import Foundation
import RealmSwift

class Category: Object {
    @Persisted(primaryKey: true) var name: String = ""
    @Persisted var quotes: List<Quote>
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
