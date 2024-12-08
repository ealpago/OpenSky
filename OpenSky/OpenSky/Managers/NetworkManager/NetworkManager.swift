import Foundation

protocol NetworkManagerProtocol {
    func request<T: Decodable>(
        request: BaseRequest,
        responseModel: T.Type
    ) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager(session: URLSession(configuration: .default))
    private let session: URLSession

    private init(session: URLSession) {
        self.session = session
    }

    func request<T: Decodable>(
        request: BaseRequest,
        responseModel: T.Type
    ) async throws -> T {
        var urlComponents = URLComponents(string: request.path)
        if let queryParameters = request.queryParameters {
            urlComponents?.queryItems = queryParameters.compactMap { key, value in
                guard let value = value else { return nil }
                return URLQueryItem(name: key, value: "\(value)")
            }
        }
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        urlRequest.httpBody = request.body
        do {
            let (data, response) = try await session.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.requestFailed
            }
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            if let decodingError = error as? DecodingError {
                throw NetworkError.decodingError(decodingError)
            }
            throw NetworkError.requestFailed
        }
    }
}
