struct AlertMessage: Equatable {
    let message: String
    let type: AlertType
    
    enum AlertType {
        case success
        case error
        case info
        case warning
    }
    
    static func success(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .success)
    }
    
    static func error(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .error)
    }
    
    static func info(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .info)
    }
    
    static func warning(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .warning)
    }
}

