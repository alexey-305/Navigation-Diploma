//
//  KeychainManager.swift
//  Navigation
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private let service = "com.navigation.realmEncryption"
    private let account = "realmKey"
    
    // MARK: - Public
    
    /// Возвращает ключ шифрования: читает из Keychain или генерирует новый
    func getOrCreateEncryptionKey() -> Data {
        if let existingKey = readKey() {
            print("🔑 Ключ шифрования загружен из Keychain")
            return existingKey
        }
        let newKey = generateKey()
        saveKey(newKey)
        print("🔑 Новый ключ шифрования сгенерирован и сохранён в Keychain")
        return newKey
    }
    
    /// Удаляет ключ из Keychain (используется при пересоздании базы)
    func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("🗑️ Ключ удалён из Keychain")
        } else {
            print("⚠️ Ключ не найден в Keychain или ошибка удаления: \(status)")
        }
    }
    
    // MARK: - Private
    
    /// Генерирует случайный 64-байтовый ключ (требование Realm)
    private func generateKey() -> Data {
        var key = Data(count: 64)
        _ = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes.baseAddress!)
        }
        return key
    }
    
    /// Сохраняет ключ в Keychain
    private func saveKey(_ key: Data) {
        let query: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrService as String:    service,
            kSecAttrAccount as String:    account,
            kSecValueData as String:      key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Ошибка сохранения ключа в Keychain: \(status)")
        }
    }
    
    /// Читает ключ из Keychain
    private func readKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }
}
