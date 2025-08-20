import SwiftUI
import Foundation

struct HabitationChatView: View {
    let senderId: String
    let receiverId: String
    let receiverName: String
    
    @StateObject private var viewModel = HabitationChatViewModel()
    @State private var messageText = ""
    @Environment(\.presentationMode) var presentationMode
    
    init(senderId: String, receiverId: String, receiverName: String) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.receiverName = receiverName
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
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
            if viewModel.messages.isEmpty {
                viewModel.addMockMessage(sender: receiverId, receiver: senderId)
            }
            
            if senderId.isEmpty {
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
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
            
            HStack(spacing: 12) {
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

#Preview {
    HabitationChatView(
        senderId: "68720948d459300a9c088563",
        receiverId: "687202cbd459300a9c08854e",
        receiverName: "John Doe"
    )
}
