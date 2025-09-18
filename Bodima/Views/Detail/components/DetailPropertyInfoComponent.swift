import SwiftUI

// Property information display with comprehensive details and status indicators
// Handles property metadata, location, ratings, and availability status
struct DetailPropertyInfoComponent: View {
    let habitation: EnhancedHabitationData
    let locationData: LocationData?
    
    // Computed property for address formatting with fallback handling
    private var fullAddress: String {
        guard let location = locationData else { 
            if let user = habitation.user {
                return "\(user.phoneNumber)" 
            } else {
                return "Unknown location"
            }
        }
        return "\(location.addressNo), \(location.addressLine01), \(location.city), \(location.district)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Property title with type badge
            HStack {
                Text(habitation.name)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Spacer()
                
                Text(habitation.type)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Property description with full text display
            Text(habitation.description)
                .font(.subheadline)
                .foregroundStyle(AppColors.foreground)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            // Location information with primary styling
            Text(fullAddress)
                .font(.subheadline)
                .foregroundStyle(AppColors.primary)
            
            // Rating and availability status row
            HStack(spacing: 8) {
                // Rating display with star icon
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                Text("4.5")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.foreground)
                Text("(235)")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
                
                Spacer()
                
                // Availability status badge with conditional styling
                if habitation.isReserved {
                    Text("Reserved")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("Available")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Contact action buttons row
            HStack(spacing: 16) {
                Button(action: {
                    // TODO: Implement phone call functionality
                }) {
                    Image(systemName: "phone")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.mutedForeground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Call")
                
                Button(action: {
                    // TODO: Implement email functionality
                }) {
                    Image(systemName: "envelope")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.mutedForeground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Email")
                
                Spacer()
            }
        }
    }
}
