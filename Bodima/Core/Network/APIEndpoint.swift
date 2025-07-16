import Foundation

enum APIEndpoint {
    case login
    case register
    case createProfile
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .createProfile:
            return "/profie"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .createProfile:
            return .POST
        }
    }
}






