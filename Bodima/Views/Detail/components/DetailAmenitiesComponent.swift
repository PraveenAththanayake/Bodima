import SwiftUI

// Amenities grid display with feature availability indicators
// Dynamically renders property features in responsive grid layout
struct DetailAmenitiesComponent: View {
    let featureData: HabitationFeatureData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Amenities")
                .font(.title3.bold())
                .foregroundStyle(AppColors.foreground)
            
            if let feature = featureData {
                // Responsive grid layout with flexible columns for optimal space usage
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    AmenityItemView(icon: "square.fill", text: "\(feature.sqft) sq ft")
                    AmenityItemView(icon: "person.2.fill", text: feature.familyType)
                    AmenityItemView(icon: "bed.double.fill", text: "\(feature.windowsCount) Windows")
                    
                    // Conditional rendering based on feature availability
                    if feature.smallBedCount > 0 {
                        AmenityItemView(icon: "bed.double.fill", text: "\(feature.smallBedCount) Small bed\(feature.smallBedCount > 1 ? "s" : "")")
                    }
                    
                    if feature.largeBedCount > 0 {
                        AmenityItemView(icon: "bed.double.fill", text: "\(feature.largeBedCount) Large bed\(feature.largeBedCount > 1 ? "s" : "")")
                    }
                    
                    if feature.chairCount > 0 {
                        AmenityItemView(icon: "chair.fill", text: "\(feature.chairCount) Chair\(feature.chairCount > 1 ? "s" : "")")
                    }
                    
                    if feature.tableCount > 0 {
                        AmenityItemView(icon: "table.fill", text: "\(feature.tableCount) Table\(feature.tableCount > 1 ? "s" : "")")
                    }
                    
                    if feature.isElectricityAvailable {
                        AmenityItemView(icon: "bolt.fill", text: "Electricity")
                    }
                    
                    if feature.isWachineMachineAvailable {
                        AmenityItemView(icon: "washer.fill", text: "Washing machine")
                    }
                    
                    if feature.isWaterAvailable {
                        AmenityItemView(icon: "drop.fill", text: "Water")
                    }
                }
            } else {
                // Fallback state when no amenity data is available
                Text("No amenity information available")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
                    .padding(.vertical, 20)
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

// Individual amenity item with icon and text display
// Reusable component for consistent amenity presentation
struct AmenityItemView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.mutedForeground)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.foreground)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
}
