import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://bodima-backend-api.vercel.app"
    
    private init() {}
    
    // MARK: - GET Request without body
    func request<T: Codable>(
        endpoint: APIEndpoint,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔍 DEBUG - Making GET request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - POST/PUT Request with body
    func request<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Request with custom headers (for JWT authorization)
    func requestWithHeaders<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        headers: [String: String],
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default headers if not already present
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Encode body
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        // Log request details
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - GET Request with custom headers
    func requestWithHeaders<T: Codable>(
        endpoint: APIEndpoint,
        headers: [String: String],
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        print("🔍 DEBUG - Making GET request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Response Handler
    private func handleResponse<T: Codable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        if let error = error {
            print("🔍 DEBUG - Network Error: \(error)")
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }
        
        print("🔍 DEBUG - Response Status Code: \(httpResponse.statusCode)")
        
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        // Log response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 DEBUG - Response Data: \(responseString)")
        }
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                print("🔍 DEBUG - Decoding Error: \(error)")
                completion(.failure(NetworkError.decodingError))
            }
            
        case 401:
            // Unauthorized - token expired or invalid
            print("🔍 DEBUG - 401 Unauthorized - Token may be expired")
            completion(.failure(NetworkError.unauthorized))
            
        case 400...499:
            // Client error - try to decode error response
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                completion(.failure(NetworkError.clientError(errorResponse.message)))
            } catch {
                // Fallback to generic client error
                completion(.failure(NetworkError.clientError("Client error occurred")))
            }
            
        case 500...599:
            // Server error
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                completion(.failure(NetworkError.serverError(errorResponse.message)))
            } catch {
                completion(.failure(NetworkError.serverError("Server error occurred")))
            }
            
        default:
            completion(.failure(NetworkError.unknownError))
        }
    }
}

// MARK: - Network Error Types
enum NetworkError: Error {
    case invalidURL
    case encodingError
    case decodingError
    case invalidResponse
    case noData
    case unauthorized
    case clientError(String)
    case serverError(String)
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .clientError(let message):
            return message
        case .serverError(let message):
            return message
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let success: Bool?
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? "Unknown error"
    }
}




extension NetworkManager {
    func requestWithHeaders<U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        headers: [String: String],
        responseType: [String: Any].Type,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default headers if not already present
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Encode body
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleJSONResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    private func handleJSONResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        if let error = error {
            print("🔍 DEBUG - Network Error: \(error)")
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }
        
        print("🔍 DEBUG - Response Status Code: \(httpResponse.statusCode)")
        
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        // Log response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 DEBUG - Response Data: \(responseString)")
        }
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NetworkError.decodingError))
                }
            } catch {
                print("🔍 DEBUG - JSON Parsing Error: \(error)")
                completion(.failure(NetworkError.decodingError))
            }
            
        case 401:
            completion(.failure(NetworkError.unauthorized))
            
        case 400...499:
            // Try to parse error message from JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = json["message"] as? String {
                    completion(.failure(NetworkError.clientError(message)))
                } else {
                    completion(.failure(NetworkError.clientError("Client error occurred")))
                }
            } catch {
                completion(.failure(NetworkError.clientError("Client error occurred")))
            }
            
        case 500...599:
            // Server error
            completion(.failure(NetworkError.serverError("Server error occurred")))
            
        default:
            completion(.failure(NetworkError.unknownError))
        }
    }
}
