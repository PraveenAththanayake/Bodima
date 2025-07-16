import Foundation

class ErrorHandler {
    static func getErrorMessage(for error: Error) -> String {
        if let nsError = error as NSError? {
            switch nsError.code {
            case 400:
                return nsError.localizedDescription
            case 401:
                return "Invalid credentials. Please try again."
            case 403:
                return "Access denied. Please check your permissions."
            case 404:
                return "Service not found. Please try again later."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return nsError.localizedDescription
            }
        } else {
            switch error {
            case NetworkError.invalidURL:
                return "Invalid server URL"
            case NetworkError.noData:
                return "No response from server"
            case NetworkError.decodingError:
                return "Failed to process server response"
            default:
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}
