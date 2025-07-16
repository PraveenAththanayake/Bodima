enum APIEndpoint {
    case login
    case register
    case createProfile(userId: String)
    case getUserProfile(userId: String)

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .createProfile(let userId):
            return "/users/\(userId)"
        case .getUserProfile(let userId):
            return "/users/\(userId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .createProfile:
            return .POST
        case .getUserProfile:
            return .GET
        }
    }
}
