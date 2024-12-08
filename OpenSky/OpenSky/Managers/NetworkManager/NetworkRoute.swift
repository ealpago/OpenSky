//
//  NetworkRoute.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

protocol NetworkRoute {
    var method: HTTPMethods { get }
    var path: String { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}
