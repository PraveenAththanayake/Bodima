import SwiftUI

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