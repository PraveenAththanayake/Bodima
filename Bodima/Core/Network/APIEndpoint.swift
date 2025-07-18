enum APIEndpoint {
    case login
    case register
    case createProfile(userId: String)
    case getUserProfile(userId: String)
    case createHabitation
    case getHabitationById(habitationId: String)
    case createLocation
    case createHabitationFeature(habitationId: String)

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
        case .createHabitation:
            return "/habitations"
        case .getHabitationById(let habitationId):
            return "/habitations/\(habitationId)"
        case .createLocation:
            return "/locations"
        case .createHabitationFeature(let habitationId):
            return "/habitation-feature/\(habitationId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .createProfile, .createHabitation, .createLocation, .createHabitationFeature:
            return .POST
        case .getUserProfile, .getHabitationById:
            return .GET
        }
    }
}
