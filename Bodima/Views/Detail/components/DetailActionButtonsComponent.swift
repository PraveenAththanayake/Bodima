import SwiftUI

// Social action buttons for user engagement (like, share, bookmark)
// Manages interaction states with smooth animations and haptic feedback
struct DetailActionButtonsComponent: View {
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    @Binding var isBookmarked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Like button with count display and animated state transitions
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isLiked.toggle()
                    likesCount += isLiked ? 1 : -1
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundStyle(isLiked ? AppColors.primary : AppColors.mutedForeground)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                    
                    if likesCount > 0 {
                        Text("\(likesCount)")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.foreground)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLiked ? "Unlike" : "Like")
            
            // Share button for social distribution
            Button(action: {
                // TODO: Implement share functionality with native share sheet
            }) {
                Image(systemName: "paperplane")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.mutedForeground)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share")
            
            Spacer()
            
            // Bookmark button with persistent state management
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isBookmarked.toggle()
                }
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundStyle(isBookmarked ? AppColors.primary : AppColors.mutedForeground)
                    .scaleEffect(isBookmarked ? 1.1 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark")
        }
    }
}
