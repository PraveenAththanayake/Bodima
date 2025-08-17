import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(id: 1, text: "Hello! Nice to contact with you.", isFromCurrentUser: false, timestamp: "12-03-2025"),
        Message(id: 2, text: "Hello! Nice to contact with you.", isFromCurrentUser: true, timestamp: "12-03-2025")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
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
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: {}) {
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
                        Text("AF")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.foreground)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alex Fox")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.foreground)
                    
                    Text("@alexfox")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "phone")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.foreground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Call")
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.foreground)
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More options")
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.background)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = Message(
            id: messages.count + 1,
            text: messageText,
            isFromCurrentUser: true,
            timestamp: getCurrentTimeString()
        )
        
        messages.append(newMessage)
        messageText = ""
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: Date())
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
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
                    
                    Text(message.timestamp)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.mutedForeground)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
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
                    
                    Text(message.timestamp)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.mutedForeground)
                        .padding(.leading, 8)
                }
                
                Spacer()
            }
        }
    }
}

struct Message: Identifiable {
    let id: Int
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: String
}

#Preview {
    ChatView()
}
