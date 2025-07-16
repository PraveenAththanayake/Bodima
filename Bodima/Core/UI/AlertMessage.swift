struct AlertMessage {
    let message: String
    let type: AlertType
    
    static func success(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .success)
    }
    
    static func error(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .error)
    }
    
    static func warning(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .warning)
    }
    
    static func info(_ message: String) -> AlertMessage {
        AlertMessage(message: message, type: .info)
    }
}
