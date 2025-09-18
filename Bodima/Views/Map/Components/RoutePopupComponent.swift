import SwiftUI
import CoreLocation

struct RoutePopupComponent: View {
    let habitation: EnhancedHabitationData
    let routeDistance: CLLocationDistance
    let isCalculatingRoute: Bool
    let onClose: () -> Void
    let onSeeDetails: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 16) {
                popupHeader
                distanceInformation
                actionButtons
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    private var popupHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habitation.name)
                    .font(.headline.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Route Information")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.mutedForeground)
            }
        }
    }
    
    private var distanceInformation: some View {
        Group {
            if isCalculatingRoute {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Calculating route...")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Distance from your location")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.foreground)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(formatDistance(routeDistance))
                            .font(.title2.bold())
                            .foregroundStyle(AppColors.primary)
                        
                        Spacer()
                        
                        Text("≈ \(formatTravelTime(routeDistance)) walk")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                }
                .padding()
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
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Text("Close")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.foreground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            
            Button(action: onSeeDetails) {
                Text("See Details")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    private func formatTravelTime(_ distance: CLLocationDistance) -> String {
        let timeInSeconds = distance / 1.39
        let minutes = Int(timeInSeconds / 60)
        
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

#Preview {
    let sampleData = """
    {
        "_id": "1",
        "user": null,
        "name": "Cozy Apartment",
        "description": "Beautiful place",
        "type": "apartment",
        "isReserved": false,
        "createdAt": "2024-01-01T00:00:00Z",
        "updatedAt": "2024-01-01T00:00:00Z",
        "__v": 0,
        "price": 25000,
        "pictures": null
    }
    """.data(using: .utf8)!
    
    let habitation = try! JSONDecoder().decode(EnhancedHabitationData.self, from: sampleData)
    
    return RoutePopupComponent(
        habitation: habitation,
        routeDistance: 1500,
        isCalculatingRoute: false,
        onClose: {},
        onSeeDetails: {}
    )
}
