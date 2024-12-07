//
//  BaseRequest.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

protocol BaseRequest: Encodable {
    var path: String { get }
    var method: HTTPMethods { get }
    var headers: [String: String]? { get }
    var queryParameters: [String : Any?]? { get }
    var body: Data? { get }
}

extension BaseRequest {
    func toData() throws -> Data? {
        return try JSONEncoder().encode(self)
    }
}
