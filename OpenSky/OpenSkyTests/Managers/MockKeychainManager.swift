//
//  MockKeychainManager.swift
//  OpenSkyTests
//
//  Created by Emre Alpago on 9.12.2024.
//

@testable import OpenSky

final class MockKeychainManager: KeychainManagerInterface {
    private var keychainStorage: [String: String] = [:]

    var invokedSave = false
    var invokedSaveCount = 0
    var invokedSaveParameters: (key: String, value: String)?
    var invokedSaveParametersList = [(key: String, value: String)]()

    var invokedRetrieve = false
    var invokedRetrieveCount = 0
    var invokedRetrieveParameters: String?
    var invokedRetrieveParametersList = [String]()

    static var shared = MockKeychainManager()

    private init() {}

    static func save(key: String, value: String) -> Bool {
        shared.invokedSave = true
        shared.invokedSaveCount += 1
        shared.invokedSaveParameters = (key, value)
        shared.invokedSaveParametersList.append((key, value))
        shared.keychainStorage[key] = value
        return true
    }

    static func retrieve(key: String) -> String? {
        shared.invokedRetrieve = true
        shared.invokedRetrieveCount += 1
        shared.invokedRetrieveParameters = key
        shared.invokedRetrieveParametersList.append(key)
        return shared.keychainStorage[key]
    }
}

