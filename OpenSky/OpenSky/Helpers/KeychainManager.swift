//
//  KeychainManager.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation
import Security

class KeychainManager {
    static func save(key: String, value: String) -> Bool {
        let data = Data(value.utf8)
        // Create query to save the item in Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        // Delete any existing item with the same key (this avoids duplicates)
        SecItemDelete(query as CFDictionary)
        // Add the item to the Keychain
        let result = SecItemAdd(query as CFDictionary, nil)
        // Return true if successful, false otherwise
        return result == errSecSuccess
    }

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
}
