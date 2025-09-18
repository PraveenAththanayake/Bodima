enum APIEndpoint {
    case login
    case register
    case verifyToken
    case createProfile(userId: String)
    case updateProfile(userId: String)
    case getUserProfile(userId: String)
    case getUserProfileByAuth(authId: String)
    case createHabitation
    case updateHabitation(habitationId: String)
    case deleteHabitation(habitationId: String)
    case addHabitaionImage(habitationId: String)
    case getHabitations
    case getHabitationsByUserId(userId: String)
    case getLocationByHabitationId(habitationId: String)
    case getHabitationById(habitationId: String)
    case getFeaturesByHabitationId(habitationId: String)
    case createLocation
    case createHabitationFeature(habitationId: String)
    case createReservation
    case getReservation(reservationId: String)
    case confirmReservation(reservationId: String)
    case checkReservationExpiration(reservationId: String)
    case checkAvailability
    case getReservedDates(habitationId: String)
    case getHabitationAvailability(habitationId: String, queryParams: [String: String])
    case getUserReservations(userId: String)
    case createPayment
    case createStories
    case getUserStories
    case sendMessage
    case getNotifications
    case markNotificationAsRead(notificationId: String)
    case getDashboard(userId: String)
    case getDashboardSummary(userId: String)
    case getAccessibilitySettings(userId: String)
    case updateAccessibilitySettings(userId: String)

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .verifyToken:
            return "/auth/verify-token"
        case .createProfile(let userId):
            return "/users/\(userId)"
        case .updateProfile(let userId):
            return "/users/\(userId)"
        case .getUserProfile(let userId):
            return "/users/\(userId)"
        case .getUserProfileByAuth(let authId):
            return "/users/\(authId)"
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
        case .getHabitationsByUserId(let userId):
            return "/habitations/user/\(userId)"
        case .getLocationByHabitationId(let habitationId):
            return "/locations/habitation/\(habitationId)"
        case .getFeaturesByHabitationId(let habitationId):
            return "/habitation-feature/\(habitationId)"
        case .createReservation:
            return "/reservations"
        case .getReservation(let reservationId):
            return "/reservations/\(reservationId)"
        case .confirmReservation(let reservationId):
            return "/reservations/\(reservationId)/confirm"
        case .checkReservationExpiration(let reservationId):
            return "/reservations/\(reservationId)/check-expiration"
        case .checkAvailability:
            return "/reservations/check-availability"
        case .getReservedDates(let habitationId):
            return "/reservations/habitation/\(habitationId)/reserved-dates"
        case .getHabitationAvailability(let habitationId):
            return "/reservations/habitation/\(habitationId)/availability"
        case .getUserReservations(let userId):
            return "/reservations/user/\(userId)/history"
        case .createPayment:
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
        case .getDashboard(let userId):
            return "/dashboard/\(userId)"
        case .getDashboardSummary(let userId):
            return "/dashboard/\(userId)/summary"
        case .getAccessibilitySettings(let userId):
            return "/users/\(userId)/accessibility"
        case .updateAccessibilitySettings(let userId):
            return "/users/\(userId)/accessibility"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .verifyToken, .createProfile, .createHabitation, .createLocation, .createHabitationFeature, .addHabitaionImage, .createReservation, .checkReservationExpiration, .checkAvailability, .createPayment, .createStories, .sendMessage, .markNotificationAsRead:
            return .POST
        case .getUserProfile, .getUserProfileByAuth, .getHabitationById, .getHabitations, .getHabitationsByUserId, .getLocationByHabitationId, .getFeaturesByHabitationId, .getReservation, .getReservedDates, .getHabitationAvailability, .getUserReservations, .getUserStories, .getNotifications, .getDashboard, .getDashboardSummary, .getAccessibilitySettings:
            return .GET
        case .updateProfile, .updateHabitation, .confirmReservation, .updateAccessibilitySettings:
            return .PUT
        case .deleteHabitation:
            return .DELETE
        }
    }
}
