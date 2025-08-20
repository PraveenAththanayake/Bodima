import SwiftUI

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