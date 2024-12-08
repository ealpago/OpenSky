//
//  SetupManager.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

class SetupManager {
    static func configure() {
        let didSaveUsername = KeychainManager.save(key: "username", value: "Alpago")
        let didSavePassword = KeychainManager.save(key: "password", value: "Ea184822")

        if !didSaveUsername || !didSavePassword {
            print("Failed to save credentials to Keychain")
        } else {
            print("Credentials successfully saved to Keychain")
        }
    }
}

