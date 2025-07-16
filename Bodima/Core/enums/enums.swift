enum AlertType {
    case success
    case error
    case warning
    case info
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}
