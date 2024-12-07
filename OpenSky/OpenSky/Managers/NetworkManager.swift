import Foundation

protocol NetworkManagerInterface {
    func request<T: Codable>(
        route: NetworkRoute,
        responseModel: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    )
}

final class NetworkManager: NetworkManagerInterface {
    static let shared = NetworkManager(session: URLSession(configuration: .default))
    private let session: URLSession

    private init(session: URLSession) {
        self.session = session
    }

    func request<T: Codable>(
        route: NetworkRoute,
        responseModel: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = URL(string: route.path) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = route.method.rawValue
        if let headers = route.headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = route.body

        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network Error: \(error)")
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
