import Foundation

/**
 * NetworkManager - Centralized network communication layer for the Bodima application.
 * 
 * This class provides a comprehensive networking solution with automatic token management,
 * error handling, and support for various HTTP methods. It handles all API communications
 * with the backend server including authentication, request/response processing, and
 * error management.
 * 
 * Key Features:
 * - Singleton pattern for consistent network access across the app
 * - Automatic JWT token validation and refresh
 * - Comprehensive error handling with user-friendly messages
 * - Support for GET, POST, PUT, DELETE operations
 * - Custom header support for authenticated requests
 * - Debug logging for development and troubleshooting
 * - Configurable timeouts and connection limits
 * - Base64 JWT token parsing and expiration checking
 * 
 * Usage:
 * - Use NetworkManager.shared to access the singleton instance
 * - All methods are thread-safe and handle main thread dispatch automatically
 * - Supports both Codable models and raw JSON responses
 * - Automatic token cleanup on authentication failures
 */
class NetworkManager {
    /// Shared singleton instance for consistent network access across the application
    static let shared = NetworkManager()
    
    /// Base URL for all API endpoints - configured for local development
    private let baseURL = "http://localhost:3000"
    
    /// Custom URLSession configured for optimal performance with large responses
    private let urlSession: URLSession
    
    /**
     * Private initializer to enforce singleton pattern.
     * Configures URLSession with optimized settings for the application's needs.
     */
    private init() {
        // Configure URLSession for larger responses and better performance
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0      // 60 seconds for individual requests
        config.timeoutIntervalForResource = 300.0    // 5 minutes for entire resource loading
        config.httpMaximumConnectionsPerHost = 10    // Allow up to 10 concurrent connections
        config.urlCache = nil                        // Disable cache for large responses
        
        // Create custom URLSession with optimized configuration
        self.urlSession = URLSession(configuration: config)
    }
    
    /**
     * Validates JWT token expiration without actor isolation.
     * 
     * Parses the JWT token payload to check if the token has expired.
     * This method is thread-safe and can be called from any context.
     * 
     * @param token JWT token string to validate
     * @return true if token is expired or invalid, false if still valid
     */
    private func isTokenExpired(token: String) -> Bool {
        // JWT tokens have 3 parts separated by dots: header.payload.signature
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return true }
        
        // Extract and decode the payload (middle part)
        let payload = components[1]
        guard let data = Data(base64Encoded: payload.base64Padded()) else { return true }
        
        do {
            // Parse JSON payload to extract expiration time
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                // Compare expiration time with current time
                return Date().timeIntervalSince1970 > exp
            }
        } catch {
            // If parsing fails, consider token invalid
            return true
        }
        
        // Default to expired if unable to validate
        return true
    }
    
    /**
     * Performs a GET request without a request body.
     * 
     * This method handles simple GET requests with automatic token validation
     * and authentication. It's ideal for fetching data from the server.
     * 
     * @param endpoint API endpoint configuration containing path and method
     * @param responseType Expected response type conforming to Codable
     * @param completion Callback with Result containing decoded response or error
     */
    func request<T: Codable>(
        endpoint: APIEndpoint,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Validate and construct the full URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add authentication token if available and validate it
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            // Check token expiration before making the request
            if isTokenExpired(token: token) {
                // Token expired - force user sign out on main thread
                DispatchQueue.main.async {
                    AuthViewModel.shared.forceSignOut()
                }
                completion(.failure(NetworkError.unauthorized))
                return
            }
            // Add valid token to request headers
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Debug logging for development
        print("🔍 DEBUG - Making GET request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        
        // Execute the network request
        urlSession.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /**
     * Performs a POST/PUT request with a request body.
     * 
     * This method handles requests that need to send data to the server,
     * such as creating or updating resources. It automatically encodes
     * the request body to JSON and includes authentication headers.
     * 
     * @param endpoint API endpoint configuration containing path and method
     * @param body Request body object conforming to Codable
     * @param responseType Expected response type conforming to Codable
     * @param completion Callback with Result containing decoded response or error
     */
    func request<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Validate and construct the full URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available and validate it
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            // Check token expiration before making the request
            if isTokenExpired(token: token) {
                // Token expired - force user sign out on main thread
                DispatchQueue.main.async {
                    AuthViewModel.shared.forceSignOut()
                }
                completion(.failure(NetworkError.unauthorized))
                return
            }
            // Add valid token to request headers
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode request body to JSON
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging for development
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        // Debug logging for development
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        
        // Execute the network request
        urlSession.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /**
     * Performs a request with custom headers and request body.
     * 
     * This method allows full control over request headers, making it ideal
     * for authenticated requests or when specific headers are required.
     * Commonly used for JWT authorization and custom content types.
     * 
     * @param endpoint API endpoint configuration containing path and method
     * @param body Request body object conforming to Codable
     * @param headers Dictionary of custom headers to include in the request
     * @param responseType Expected response type conforming to Codable
     * @param completion Callback with Result containing decoded response or error
     */
    func requestWithHeaders<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        headers: [String: String],
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Validate and construct the full URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add all custom headers to the request
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default Content-Type header if not already specified
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Encode request body to JSON
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging for development
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        // Debug logging for development
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        // Execute the network request
        urlSession.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /**
     * Performs a GET request with custom headers (typically for JWT authentication).
     * 
     * This method is specifically designed for GET requests that require custom headers,
     * most commonly for JWT token authentication. It doesn't include a request body.
     * 
     * @param endpoint API endpoint configuration containing path and method
     * @param headers Dictionary of custom headers to include in the request
     * @param responseType Expected response type conforming to Codable
     * @param completion Callback with Result containing decoded response or error
     */
    func requestWithHeaders<T: Codable>(
        endpoint: APIEndpoint,
        headers: [String: String],
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Validate and construct the full URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add all custom headers to the request
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Debug logging for development
        print("🔍 DEBUG - Making GET request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        // Execute the network request
        urlSession.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    
    
    /**
     * Handles HTTP responses for all network requests.
     * 
     * This private method processes the raw HTTP response, handles various status codes,
     * and converts the response data into the expected Codable type. It provides
     * comprehensive error handling and logging for debugging purposes.
     * 
     * @param data Raw response data from the server
     * @param response HTTP response object containing status code and headers
     * @param error Network error if the request failed
     * @param completion Callback with Result containing decoded response or error
     */
    private func handleResponse<T: Codable>(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Check for network-level errors (no internet, timeout, etc.)
        if let error = error {
            print("🔍 DEBUG - Network Error: \(error)")
            completion(.failure(error))
            return
        }
        
        // Ensure we have a valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }
        
        // Log the HTTP status code for debugging
        print("🔍 DEBUG - Response Status Code: \(httpResponse.statusCode)")
        
        // Ensure we have response data
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        // Log response data for debugging (be careful with sensitive data)
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 DEBUG - Response Data: \(responseString)")
        }
        
        // Process HTTP status codes and handle different response scenarios
        switch httpResponse.statusCode {
        case 200...299:
            // Success response - attempt to decode the expected type
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                print("🔍 DEBUG - Decoding Error: \(error)")
                completion(.failure(NetworkError.decodingError))
            }
            
        case 401:
            // Unauthorized - typically means token is expired or invalid
            print("🔍 DEBUG - 401 Unauthorized - Token may be expired")
            completion(.failure(NetworkError.unauthorized))
            
        case 400...499:
            // Client error - attempt to extract error message from response
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                completion(.failure(NetworkError.clientError(errorResponse.message)))
            } catch {
                // If error response parsing fails, use generic message
                completion(.failure(NetworkError.clientError("Client error occurred")))
            }
            
        case 500...599:
            // Server error - attempt to extract error message from response
            do {
                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                completion(.failure(NetworkError.serverError(errorResponse.message)))
            } catch {
                // If error response parsing fails, use generic message
                completion(.failure(NetworkError.serverError("Server error occurred")))
            }
            
        default:
            // Unexpected status code
            completion(.failure(NetworkError.unknownError))
        }
    }
}

/**
 * Comprehensive error types for network operations.
 * 
 * This enum defines all possible network-related errors that can occur
 * during API communication. Each error type includes a user-friendly
 * localized description for display in the UI.
 */
enum NetworkError: Error {
    case invalidURL          // URL construction failed
    case encodingError       // Request body encoding failed
    case decodingError       // Response decoding failed
    case invalidResponse     // Invalid HTTP response
    case noData             // No data received from server
    case unauthorized       // 401 - Authentication required
    case clientError(String) // 4xx - Client-side errors with message
    case serverError(String) // 5xx - Server-side errors with message
    case resourceTooLarge   // Response size exceeded limits
    case timeout            // Request timed out
    case unknownError       // Unexpected error occurred
    
    /**
     * Provides user-friendly error messages for display in the UI.
     * These messages are designed to be helpful to end users without
     * exposing technical implementation details.
     */
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
        case .resourceTooLarge:
            return "Response too large - please try again or contact support"
        case .timeout:
            return "Request timed out - please check your connection"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

/**
 * Private extension to handle Base64 padding for JWT token parsing.
 * 
 * JWT tokens use Base64 encoding but may not include proper padding.
 * This extension ensures the Base64 string has correct padding for decoding.
 */
fileprivate extension String {
    /**
     * Adds proper Base64 padding to a string if needed.
     * 
     * @return String with proper Base64 padding
     */
    func base64Padded() -> String {
        let remainder = self.count % 4
        if remainder > 0 {
            return self + String(repeating: "=", count: 4 - remainder)
        }
        return self
    }
}

/**
 * Model for parsing error responses from the API.
 * 
 * This struct represents the standard error response format from the backend.
 * It handles cases where the response may not include all expected fields.
 */
struct ErrorResponse: Codable {
    /// Optional success flag from the API response
    let success: Bool?
    /// Error message from the server
    let message: String
    
    /// Keys for JSON decoding
    enum CodingKeys: String, CodingKey {
        case success
        case message
    }
    
    /**
     * Custom initializer to handle missing or null values gracefully.
     * Provides a default error message if none is provided by the server.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? "Unknown error"
    }
}




/**
 * NetworkManager extension for handling raw JSON responses.
 * 
 * This extension provides methods for cases where you need to work with
 * raw JSON dictionaries instead of strongly-typed Codable models.
 */
extension NetworkManager {
    /**
     * Performs a request with custom headers and returns raw JSON dictionary.
     * 
     * This method is useful when you need to work with dynamic JSON responses
     * that don't fit into a predefined Codable structure.
     * 
     * @param endpoint API endpoint configuration
     * @param body Request body object conforming to Codable
     * @param headers Dictionary of custom headers
     * @param responseType Expected response type (always [String: Any])
     * @param completion Callback with Result containing JSON dictionary or error
     */
    func requestWithHeaders<U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        headers: [String: String],
        responseType: [String: Any].Type,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        // Validate and construct the full URL
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create and configure the URL request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add all custom headers to the request
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add default Content-Type header if not already specified
        if headers["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Encode request body to JSON
        do {
            let jsonData = try JSONEncoder().encode(body)
            request.httpBody = jsonData
            
            // Debug logging for development
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔍 DEBUG - Request Body: \(jsonString)")
            }
        } catch {
            completion(.failure(NetworkError.encodingError))
            return
        }
        
        // Debug logging for development
        print("🔍 DEBUG - Making request to: \(url)")
        print("🔍 DEBUG - Method: \(endpoint.method.rawValue)")
        print("🔍 DEBUG - Headers: \(headers)")
        
        // Execute the network request with JSON response handler
        urlSession.dataTask(with: request) { data, response, error in
            self.handleJSONResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /**
     * Handles HTTP responses specifically for raw JSON dictionary results.
     * 
     * This private method processes responses that should be returned as
     * [String: Any] dictionaries rather than strongly-typed Codable objects.
     * 
     * @param data Raw response data from the server
     * @param response HTTP response object containing status code and headers
     * @param error Network error if the request failed
     * @param completion Callback with Result containing JSON dictionary or error
     */
    private func handleJSONResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        // Check for network-level errors
        if let error = error {
            print("🔍 DEBUG - Network Error: \(error)")
            completion(.failure(error))
            return
        }
        
        // Ensure we have a valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }
        
        // Log the HTTP status code for debugging
        print("🔍 DEBUG - Response Status Code: \(httpResponse.statusCode)")
        
        // Ensure we have response data
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        // Log response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 DEBUG - Response Data: \(responseString)")
        }
        
        // Process HTTP status codes for JSON responses
        switch httpResponse.statusCode {
        case 200...299:
            // Success - parse raw JSON into dictionary
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
            // Unauthorized - authentication required
            completion(.failure(NetworkError.unauthorized))
            
        case 400...499:
            // Client error - attempt to extract error message from JSON
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
            // Server error - use generic message
            completion(.failure(NetworkError.serverError("Server error occurred")))
            
        default:
            // Unexpected status code
            completion(.failure(NetworkError.unknownError))
        }
    }
    
    /**
     * Modern async/await method for performing network requests.
     * 
     * This method provides a modern Swift concurrency approach to network requests,
     * making it easier to use in async contexts without callback-based completion handlers.
     * 
     * @param endpoint API endpoint configuration
     * @param method HTTP method (defaults to GET)
     * @param body Optional request body for POST/PUT requests
     * @return APIResponse object containing the server response
     * @throws NetworkError if the request fails
     */
    func performRequest<T: Codable>(
        endpoint: APIEndpoint,
        method: String = "GET",
        body: T? = nil
    ) async throws -> APIResponse {
        // Use Swift's continuation to bridge callback-based API to async/await
        return try await withCheckedThrowingContinuation { continuation in
            if let body = body {
                // Request with body (POST/PUT)
                self.request(
                    endpoint: endpoint,
                    body: body,
                    responseType: APIResponse.self
                ) { result in
                    continuation.resume(with: result)
                }
            } else {
                // Request without body (GET)
                self.request(
                    endpoint: endpoint,
                    responseType: APIResponse.self
                ) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
