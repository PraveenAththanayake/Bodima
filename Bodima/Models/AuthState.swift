enum AuthState {
    case idle
    case authenticated(User)
    case unauthenticated
}

extension AuthState {
    var id: String {
        switch self {
        case .idle:
            return "idle"
        case .authenticated(let user):
            return "authenticated_\(user.id ?? user.username)"
        case .unauthenticated:
            return "unauthenticated"
        }
    }
}

extension AuthState: Equatable {
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.id == user2.id
        default:
            return false
        }
    }
}
