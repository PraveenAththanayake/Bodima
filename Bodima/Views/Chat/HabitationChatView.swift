import SwiftUI
import Foundation

// Import models and constants
import struct Bodima.User
import struct Bodima.AuthConstants

// MARK: - Message Model
struct ChatMessage: Identifiable, Codable {
    let id: String
    let sender: String?
    let receiver: String
    let message: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case sender
        case receiver
        case message
        case createdAt
        case updatedAt
    }
    
    // Computed property to determine if the message is from the current user
    func isFromCurrentUser(currentUserId: String) -> Bool {
        return sender == currentUserId
    }
    
    // Computed property to get timestamp from createdAt
    var timestamp: String {
        return createdAt
    }
}

// MARK: - Message Response Model
struct SendMessageResponse: Codable {
    let success: Bool
    let data: ChatMessage?
    let message: String?
}

// MARK: - Chat ViewModel
@MainActor
class HabitationChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    private let networkManager = NetworkManager.shared
    
    // Send a message
    func sendMessage(sender: String, receiver: String, messageText: String) {
        isLoading = true
        clearError()
        
        // Get the current user's ID from UserDefaults or use the provided sender ID
        let validSender: String
        if sender.isEmpty || sender == "current_user" {
            // Try to get user ID from UserDefaults
            if let userData = UserDefaults.standard.data(forKey: AuthConstants.userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData),
               let userId = user.id {
                validSender = userId
            } else if let userId = UserDefaults.standard.string(forKey: "user_id") {
                // Fallback to direct user_id key
                validSender = userId
            } else {
                showError("User ID not found. Please log in again.")
                isLoading = false
                return
            }
        } else {
            validSender = sender
        }
        
        let messageRequest = [
            "sender": validSender,
            "receiver": receiver,
            "message": messageText
        ]
        
        // Get auth token for headers
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found")
            isLoading = false
            return
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)"
        ]
        
        // Make API request
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
    
    // Add a mock message for testing (optional)
    func addMockMessage(sender: String, receiver: String) {
        // This is just for UI testing when no messages exist yet
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
    
    // Error handling
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

// MARK: - Habitation Chat View
struct HabitationChatView: View {
    let senderId: String
    let receiverId: String
    let receiverName: String
    
    @StateObject private var viewModel = HabitationChatViewModel()
    @State private var messageText = ""
    
    init(senderId: String, receiverId: String, receiverName: String) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.receiverName = receiverName
    }
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding()
                    } else if viewModel.messages.isEmpty {
                        emptyConversationView
                    } else {
                        ForEach(viewModel.messages) { message in
                            HabitationMessageBubble(
                                message: message.message,
                                isFromCurrentUser: message.isFromCurrentUser(currentUserId: senderId),
                                timestamp: message.timestamp
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppColors.background)
            
            // Message Input
            messageInputView
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.hasError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Add a mock welcome message if needed
            if viewModel.messages.isEmpty {
                viewModel.addMockMessage(sender: receiverId, receiver: senderId)
            }
            
            // Ensure we have a valid sender ID from UserDefaults if needed
            if senderId.isEmpty {
                // Log the issue for debugging
                print("⚠️ Warning: Empty sender ID in HabitationChatView")
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.foreground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                
                // User Avatar
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(receiverName.prefix(2).uppercased()))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(receiverName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.foreground)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.background)
            
            // Divider
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
    }
    
    private var emptyConversationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(AppColors.mutedForeground)
            
            Text("No messages yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.foreground)
            
            Text("Start the conversation by sending a message")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
            
            HStack(spacing: 12) {
                // Message Input Field
                HStack(spacing: 8) {
                    TextField("Text something...", text: $messageText)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.foreground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppColors.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        )
                }
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send message")
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.background)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage(
            sender: senderId,
            receiver: receiverId,
            messageText: messageText
        )
        
        messageText = ""
    }
}

// MARK: - Message Bubble Component for Habitation Chat
struct HabitationMessageBubble: View {
    let message: String
    let isFromCurrentUser: Bool
    let timestamp: String
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.foreground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.yellow.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        )
                    
                    Text(formatTimestamp(timestamp))
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.mutedForeground)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.foreground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        )
                    
                    Text(formatTimestamp(timestamp))
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.mutedForeground)
                        .padding(.leading, 8)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        // Format the timestamp for display
        // This is a simple implementation - you might want to enhance this
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
}

// MARK: - Chat Button for Habitation Detail View
struct ChatButton: View {
    let profileId: String
    let habitationOwnerId: String
    let ownerName: String
    
    var body: some View {
        NavigationLink {
            HabitationChatView(
                senderId: profileId,
                receiverId: habitationOwnerId,
                receiverName: ownerName
            )
        } label: {
            HStack {
                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                Text("Message")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.primary)
            .cornerRadius(12)
        }
    }
}

#Preview {
    HabitationChatView(
        senderId: "68720948d459300a9c088563",
        receiverId: "687202cbd459300a9c08854e",
        receiverName: "John Doe"
    )
}