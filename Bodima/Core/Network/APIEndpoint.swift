enum APIEndpoint {
    case login
    case register
    case createProfile(userId: String)
    case getUserProfile(userId: String)
    case createHabitation
    case updateHabitation(habitationId: String)
    case deleteHabitation(habitationId: String)
    case addHabitaionImage(habitationId: String)
    case getHabitations
    case getLocationByHabitationId(habitationId: String)
    case getHabitationById(habitationId: String)
    case getFeaturesByHabitationId(habitationId: String)
    case createLocation
    case createHabitationFeature(habitationId: String)
    case createReservation
    case getReservation(reservationId: String)
    case createPayement
    case createStories
    case getUserStories
    case sendMessage
    case getNotifications
    case markNotificationAsRead(notificationId: String)

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
        case .updateHabitation(let habitationId):
            return "/habitations/\(habitationId)"
        case .deleteHabitation(let habitationId):
            return "/habitations/\(habitationId)"
        case .addHabitaionImage(let habitationId):
            return "/habitations/\(habitationId)/pictures"
        case .getHabitationById(let habitationId):
            return "/habitations/\(habitationId)"
        case .createLocation:
            return "/locations"
        case .createHabitationFeature(let habitationId):
            return "/habitation-feature/\(habitationId)"
        case .getHabitations:
            return "/habitations"
        case .getLocationByHabitationId(let habitationId):
            return "/locations/habitation/\(habitationId)"
        case .getFeaturesByHabitationId(let habitationId):
            return "/habitation-feature/\(habitationId)"
        case .createReservation:
            return "/reservations"
        case .getReservation(let reservationId):
            return "/reservations/\(reservationId)"
        case .createPayement:
            return "/payments"
        case .createStories:
            return "/user-stories"
        case .getUserStories:
            return "/user-stories"
        case .sendMessage:
            return "/messages"
        case .getNotifications:
            return "/notifications"
        case .markNotificationAsRead(let notificationId):
            return "/notifications/\(notificationId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .createProfile, .createHabitation, .createLocation, .createHabitationFeature, .addHabitaionImage, .createReservation, .createPayement, .createStories, .sendMessage, .markNotificationAsRead:
            return .POST
        case .getUserProfile, .getHabitationById, .getHabitations, .getLocationByHabitationId, .getFeaturesByHabitationId, .getReservation, .getUserStories, .getNotifications:
            return .GET
        case .updateHabitation:
            return .PUT
        case .deleteHabitation:
            return .DELETE
        }
    }
}
