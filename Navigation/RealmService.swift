//
//  RealmService.swift
//  Navigation
//

import Foundation
import RealmSwift

class RealmService {
    static let shared = RealmService()
    
    private var realm: Realm?
    
    private init() {
        setupRealm()
    }
    
    // MARK: - Setup
    
    private func setupRealm() {
        let encryptionKey = KeychainManager.shared.getOrCreateEncryptionKey()
        
        let config = Realm.Configuration(
            encryptionKey: encryptionKey,
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    print("🔄 Миграция Realm: версия \(oldSchemaVersion) → 1")
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
        
        do {
            realm = try Realm()
            print("✅ Realm инициализирован с шифрованием")
            print("📁 Путь к базе: \(realm?.configuration.fileURL?.absoluteString ?? "неизвестен")")
        } catch {
            print("⚠️ Ошибка открытия Realm, удаляем старую базу и пересоздаём: \(error)")
            deleteRealmFiles()
            // Сбрасываем ключ и генерируем новый
            KeychainManager.shared.deleteKey()
            let newKey = KeychainManager.shared.getOrCreateEncryptionKey()
            let newConfig = Realm.Configuration(
                encryptionKey: newKey,
                schemaVersion: 1
            )
            Realm.Configuration.defaultConfiguration = newConfig
            do {
                realm = try Realm()
                print("✅ Realm пересоздан с новым ключом шифрования")
            } catch {
                print("❌ Критическая ошибка Realm: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func deleteRealmFiles() {
        guard let realmURL = Realm.Configuration.defaultConfiguration.fileURL else { return }
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]
        realmURLs.forEach { url in
            do {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Удалён файл: \(url.lastPathComponent)")
            } catch {
                print("⚠️ Не удалось удалить \(url.lastPathComponent): \(error)")
            }
        }
    }
    
    // MARK: - CREATE
    
    func saveQuote(text: String, category: String) {
        guard let realm = realm else {
            print("❌ Realm не инициализирован")
            return
        }
        
        let quote = Quote(text: text, category: category)
        
        do {
            try realm.write {
                realm.add(quote, update: .modified)
                
                if let existingCategory = realm.object(ofType: Category.self, forPrimaryKey: category) {
                    if !existingCategory.quotes.contains(where: { $0.text == text }) {
                        existingCategory.quotes.append(quote)
                    }
                } else {
                    let newCategory = Category(name: category)
                    newCategory.quotes.append(quote)
                    realm.add(newCategory, update: .modified)
                }
            }
            print("✅ Цитата сохранена (зашифровано)")
        } catch {
            print("❌ Ошибка сохранения цитаты: \(error)")
        }
    }
    
    // MARK: - Posts (CREATE)
    
    /// Заполняет базу стартовым набором постов один раз, если она ещё пустая
    func seedPostsIfNeeded() {
        guard let realm = realm else { return }
        guard realm.objects(PostObject.self).isEmpty else { return }
        
        let seed: [(author: String, description: String, assetName: String, likes: Int, views: Int)] = [
            ("Алексей", "Первый пост в ленте! Сегодня отличная погода ☀️", "post1", 5, 100),
            ("Мария", "Изучаю Swift и создаю крутые приложения 🚀", "post2", 12, 250),
            ("Иван", "CoreData — мощный инструмент для хранения данных", "post3", 8, 180),
            ("Елена", "Realm vs CoreData: что выбрать для проекта? 🤔", "post4", 15, 320)
        ]
        
        do {
            try realm.write {
                for (index, item) in seed.enumerated() {
                    let object = PostObject()
                    object.author = item.author
                    object.postDescription = item.description
                    object.imageAssetName = item.assetName
                    object.likes = item.likes
                    object.views = item.views
                    // Сдвигаем даты, чтобы сохранить исходный порядок при сортировке по createdAt
                    object.createdAt = Date().addingTimeInterval(TimeInterval(-index))
                    realm.add(object)
                }
            }
            print("✅ Стартовые посты добавлены (зашифровано)")
        } catch {
            print("❌ Ошибка заполнения постов: \(error)")
        }
    }
    
    func savePost(author: String, description: String, imageAssetName: String?, imageData: Data?, likes: Int = 0, views: Int = 0) {
        guard let realm = realm else {
            print("❌ Realm не инициализирован")
            return
        }
        
        let object = PostObject()
        object.author = author
        object.postDescription = description
        object.imageAssetName = imageAssetName
        object.imageData = imageData
        object.likes = likes
        object.views = views
        
        do {
            try realm.write {
                realm.add(object)
            }
            print("✅ Пост сохранён (зашифровано)")
        } catch {
            print("❌ Ошибка сохранения поста: \(error)")
        }
    }
    
    // MARK: - Posts (READ)
    
    func getAllPosts() -> Results<PostObject>? {
        guard let realm = realm else { return nil }
        return realm.objects(PostObject.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    // MARK: - READ
    
    func getAllQuotes() -> Results<Quote>? {
        guard let realm = realm else { return nil }
        return realm.objects(Quote.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    func getAllCategories() -> Results<Category>? {
        guard let realm = realm else { return nil }
        return realm.objects(Category.self).sorted(byKeyPath: "name", ascending: true)
    }
    
    func getQuotes(for category: String) -> Results<Quote>? {
        guard let realm = realm else { return nil }
        return realm.objects(Quote.self)
            .filter("category == %@", category)
            .sorted(byKeyPath: "createdAt", ascending: false)
    }
}
