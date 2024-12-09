//
//  StatesRequest.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

struct StatesRequest: BaseRequest {
    let lomin: Double?
    let lamin: Double?
    let lomax: Double?
    let lamax: Double?

    var path: String {
        return APIConstants.shared.openSkyBaseURL + "/states/all"
    }

    var method: HTTPMethods {
        return .get
    }

    //Using Keychain to secure username and password
    var headers: [String: String]? {
        guard let username = KeychainManager.retrieve(key: "username"), let password = KeychainManager.retrieve(key: "password") else { return nil }
        let credentials = "\(username):\(password)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        return ["Authorization": "Basic \(encodedCredentials)"]
    }

    var queryParameters: [String : Any?]? {
        return [
            "lomin": lomin,
            "lamin": lamin,
            "lomax": lomax,
            "lamax": lamax
        ]
    }

    var body: Data? {
        return nil
    }
}
