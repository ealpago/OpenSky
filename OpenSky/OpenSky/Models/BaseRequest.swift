//
//  BaseRequest.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

protocol BaseRequest: Codable {
    var path: String { get }
    var method: HTTPMethods { get }
    var headers: [String: String]? { get }
    var queryParameters: [String : Any?]? { get }
    var body: Data? { get }
}
