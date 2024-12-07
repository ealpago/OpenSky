//
//  StatesRequest.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

struct StatesRequest: BaseRequest {
    let lomin: Double
    let lamin: Double
    let lomax: Double
    let lamax: Double

    var path: String {
        return APIConstants.shared.openSkyBaseURL + "/states/all"
    }

    var method: HTTPMethods {
        return .get
    }

    var headers: [String: String]? {
        return ["Authorization": "Basic " + ("Alpago:Ea184822").data(using: .utf8)!.base64EncodedString()]
    }

    var queryParameters: [String : Any?]? {
        return [
            "lomin" : lomin,
            "lamin":  lamin,
            "lomax": lomax,
            "lamax": lamax
        ]
    }

    var body: Data? {
        return nil
    }
}
