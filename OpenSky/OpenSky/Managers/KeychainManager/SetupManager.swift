//
//  SetupManager.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

struct KeychainKeys {
    static let username = "username"
    static let password = "password"
}

class SetupManager {
    private let keychain: KeychainProtocol.Type

    init(keychain: KeychainProtocol.Type) {
        self.keychain = keychain
    }

    func configure() {
        let didSaveUsername = keychain.save(key: KeychainKeys.username, value: "Alpago")
        let didSavePassword = keychain.save(key: KeychainKeys.password, value: "Ea184822")

        if !didSaveUsername || !didSavePassword {
            print("Failed to save credentials to Keychain")
        } else {
            print("Credentials successfully saved to Keychain")
        }
    }
}
