import Foundation

protocol NetworkManagerProtocol {
    func request<T: Codable>(
        request: BaseRequest,
        responseModel: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    )
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager(session: URLSession(configuration: .default))
    private let session: URLSession

    private init(session: URLSession) {
        self.session = session
    }

    func request<T: Decodable>(
        request: BaseRequest,
        responseModel: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var urlComponents = URLComponents(string: request.path)
        if let queryParameters = request.queryParameters {
            urlComponents?.queryItems = queryParameters.compactMap { key, value in
                guard let value = value else { return nil }
                return URLQueryItem(name: key, value: "\(value)")
            }
        }
        guard let url = urlComponents?.url else {
            completion(.failure(.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        urlRequest.httpBody = request.body
        let task = session.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion(.failure(.requestFailed))
                    return
                }
                guard let data = data else {
                    completion(.failure(.requestFailed))
                    return
                }
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        task.resume()
    }
}
