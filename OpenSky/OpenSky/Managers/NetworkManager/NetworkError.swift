//
//  NetworkError.swift
//  OpenSky
//
//  Created by Emre Alpago on 7.12.2024.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingError(Error)
}
