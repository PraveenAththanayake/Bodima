import SwiftUI

// Property image display with fallback handling and optimized loading
// Manages image presentation, loading states, and responsive sizing
struct DetailPropertyImageComponent: View {
    let habitation: EnhancedHabitationData
    
    var body: some View {
        Group {
            if let pictures = habitation.pictures, !pictures.isEmpty, let firstPicture = pictures.first {
                // Cached image with loading placeholder for optimal performance
                CachedImage(url: firstPicture.pictureUrl, contentMode: .fill) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.input)
                        .frame(width: 350, height: 280)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .frame(width: 350, height: 280)
                .clipped()
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            } else {
                // Fallback placeholder when no images are available
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.input)
                    .frame(width: 350, height: 280)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(AppColors.mutedForeground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
        }
    }
}
