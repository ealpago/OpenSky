//
//  MockNetworkManager.swift
//  OpenSkyTests
//
//  Created by Emre Alpago on 9.12.2024.
//

@testable import OpenSky

final class MockNetworkManager: NetworkManagerInterface {
    var invokedRequest = false
    var invokedRequestCount = 0
    var invokedRequestParameters: (request: BaseRequest, responseModel: Any.Type)?
    var invokedRequestParametersList = [(request: BaseRequest, responseModel: Any.Type)]()
    var mockResponse: Any?
    var mockError: Error? 

    func request<T>(request: BaseRequest, responseModel: T.Type) async throws -> T where T: Decodable {
        invokedRequest = true
        invokedRequestCount += 1
        invokedRequestParameters = (request, responseModel)
        invokedRequestParametersList.append((request, responseModel))

        if let error = mockError {
            throw error
        }
        guard let response = mockResponse as? T else {
            fatalError("MockNetworkManager: mockResponse is not of type \(T.self)")
        }
        return response
    }
}

