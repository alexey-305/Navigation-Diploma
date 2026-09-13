import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PostModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    // Основной контекст для чтения (главный поток)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Фоновый контекст для записи (background поток)
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    // MARK: - CREATE
    
    func savePost(id: String, title: String, text: String, author: String, likes: Int, imageName: String?) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Проверка дубликата на backgroundContext перед сохранением
            let fetchRequest: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            fetchRequest.fetchLimit = 1
            
            do {
                let count = try self.backgroundContext.count(for: fetchRequest)
                if count > 0 {
                    print("⏳ Пост уже сохранён")
                    return
                }
            } catch {
                print("❌ Ошибка проверки: \(error)")
                return
            }
            
            let post = FavoritePost(context: self.backgroundContext)
            post.id = id
            post.titleText = title
            post.postText = text
            post.authorName = author
            post.likesCount = Int64(likes)
            post.createdAt = Date()
            post.imageName = imageName
            
            do {
                try self.backgroundContext.save()
                print("✅ Пост сохранён в CoreData (background)")
            } catch {
                print("❌ Ошибка сохранения: \(error)")
            }
        }
    }
    
    // MARK: - READ
    
    func fetchAllPosts() -> [FavoritePost] {
        let fetchRequest: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 20
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("❌ Ошибка загрузки: \(error)")
            return []
        }
    }
    
    // MARK: - READ (проверка дубликата с главного потока)
    
    /// Проверяет наличие поста по id на viewContext (вызывается с главного потока)
    func isPostAlreadySaved(id: String) -> Bool {
        let fetchRequest: NSFetchRequest<FavoritePost> = FavoritePost.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1  // оптимизация — нам нужен только факт наличия
        let count = (try? viewContext.count(for: fetchRequest)) ?? 0
        return count > 0
    }
    
    // MARK: - DELETE
    
    func deletePost(_ post: FavoritePost) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Переносим объект в backgroundContext по objectID
            let objectID = post.objectID
            let object = self.backgroundContext.object(with: objectID)
            
            self.backgroundContext.delete(object)
            
            do {
                try self.backgroundContext.save()
                print("✅ Пост удалён (background)")
            } catch {
                print("❌ Ошибка удаления: \(error)")
            }
        }
    }
    
    // MARK: - FILTER
    
    // MARK: - Кеш цитаты из сети (для офлайн-доступа, см. RandomQuoteViewModel)
    
    /// Сохраняет последнюю успешно загруженную из сети цитату, затирая предыдущий кеш —
    /// нужен только самый свежий вариант на случай отсутствия сети при следующем запуске
    func cacheQuote(value: String, category: String?) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<CachedQuote> = CachedQuote.fetchRequest()
            if let old = try? self.backgroundContext.fetch(fetchRequest) {
                old.forEach { self.backgroundContext.delete($0) }
            }
            
            let cached = CachedQuote(context: self.backgroundContext)
            cached.value = value
            cached.category = category
            cached.fetchedAt = Date()
            
            do {
                try self.backgroundContext.save()
                print("✅ Цитата закеширована для офлайн-доступа")
            } catch {
                print("❌ Ошибка кеширования цитаты: \(error)")
            }
        }
    }
    
    /// Последняя закешированная цитата — используется, если сеть недоступна
    func lastCachedQuote() -> CachedQuote? {
        let fetchRequest: NSFetchRequest<CachedQuote> = CachedQuote.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "fetchedAt", ascending: false)]
        fetchRequest.fetchLimit = 1
        return try? viewContext.fetch(fetchRequest).first
    }
}
