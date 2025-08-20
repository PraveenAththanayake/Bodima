import Foundation
import SwiftUI

@MainActor
class HabitationChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    private let networkManager = NetworkManager.shared
    
    func sendMessage(sender: String, receiver: String, messageText: String) {
        isLoading = true
        clearError()
        
        let validSender: String
        if sender.isEmpty || sender == "current_user" {
            if let userData = UserDefaults.standard.data(forKey: AuthConstants.userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData),
               let userId = user.id {
                validSender = userId
            } else if let userId = UserDefaults.standard.string(forKey: "user_id") {
                validSender = userId
            } else {
                showError("User ID not found. Please log in again.")
                isLoading = false
                return
            }
        } else {
            validSender = sender
        }
        
        let messageRequest: [String: String] = [
            "sender": validSender,
            "receiver": receiver,
            "message": messageText
        ]
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found")
            isLoading = false
            return
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .sendMessage,
            body: messageRequest,
            headers: headers,
            responseType: SendMessageResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let messageData = response.data {
                        self?.messages.append(messageData)
                        print("✅ Message sent successfully")
                    } else {
                        self?.showError(response.message ?? "Failed to send message")
                    }
                case .failure(let error):
                    print("🔍 DEBUG - Network error: \(error)")
                    self?.showError("Network error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addMockMessage(sender: String, receiver: String) {
        let mockMessage = ChatMessage(
            id: UUID().uuidString,
            sender: sender,
            receiver: receiver,
            message: "Welcome to the chat! Send a message to start the conversation.",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(mockMessage)
    }
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Chat Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
} 