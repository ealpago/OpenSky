//
//  KeychainManager.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation
import Security

protocol KeychainProtocol {
    static func save(key: String, value: String) -> Bool
    static func retrieve(key: String) -> String?
}

class KeychainManager: KeychainProtocol {
    static func save(key: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let result = SecItemAdd(query as CFDictionary, nil)
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
