import SwiftUI
import MapKit
import CoreLocation

struct MapAnnotationComponent: View {
    let annotation: MapAnnotationItem
    let isZoomedIn: Bool
    let onHabitationTap: (EnhancedHabitationData, CLLocationCoordinate2D) -> Void
    
    var body: some View {
        switch annotation.type {
        case .userLocation:
            UserLocationAnnotation()
        case .habitation(let habitation):
            HabitationAnnotation(
                habitation: habitation,
                coordinate: annotation.coordinate,
                isZoomedIn: isZoomedIn,
                onTap: { onHabitationTap(habitation, annotation.coordinate) }
            )
        }
    }
}

struct UserLocationAnnotation: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
        }
    }
}

struct HabitationAnnotation: View {
    let habitation: EnhancedHabitationData
    let coordinate: CLLocationCoordinate2D
    let isZoomedIn: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                habitationIcon
                
                if isZoomedIn {
                    habitationLabel
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var habitationIcon: some View {
        Image(systemName: getHabitationIcon(for: habitation.type))
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(getHabitationColor(for: habitation.type))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var habitationLabel: some View {
        VStack(spacing: 2) {
            Text(habitation.name)
                .font(.caption2.bold())
                .foregroundStyle(AppColors.foreground)
                .lineLimit(1)
            
            Text(habitation.type)
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func getHabitationIcon(for type: String) -> String {
        switch type.lowercased() {
        case "apartment":
            return "building.2.fill"
        case "house":
            return "house.fill"
        case "room":
            return "bed.double.fill"
        case "hostel":
            return "building.fill"
        case "studio":
            return "square.fill"
        default:
            return "house.fill"
        }
    }
    
    private func getHabitationColor(for type: String) -> Color {
        switch type.lowercased() {
        case "apartment":
            return AppColors.primary
        case "house":
            return .green
        case "room":
            return .orange
        case "hostel":
            return .purple
        case "studio":
            return .pink
        default:
            return AppColors.primary
        }
    }
}

#Preview {
    MapAnnotationComponent(
        annotation: MapAnnotationItem(
            id: "user_location",
            coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            type: .userLocation
        ),
        isZoomedIn: false,
        onHabitationTap: { _, _ in }
    )
}
