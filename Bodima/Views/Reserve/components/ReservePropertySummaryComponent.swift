import SwiftUI

// Property summary component displaying reservation property details
// Shows property image, title, address, and rating information
struct ReservePropertySummaryComponent: View {
    let propertyTitle: String
    let propertyAddress: String
    let propertyImageURL: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Details")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
            
            HStack(spacing: 12) {
                // Property image with fallback placeholder
                Group {
                    if let imageURL = propertyImageURL {
                        CachedImage(url: imageURL, contentMode: .fill) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.input)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundStyle(AppColors.mutedForeground)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.input)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(AppColors.mutedForeground)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                
                // Property information section
                VStack(alignment: .leading, spacing: 4) {
                    Text(propertyTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                        .lineLimit(2)
                    
                    Text(propertyAddress)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                        .lineLimit(2)
                    
                    // Rating display with consistent styling
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                        Text("4.5")
                            .font(.caption)
                            .foregroundStyle(AppColors.foreground)
                        Text("(235)")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
