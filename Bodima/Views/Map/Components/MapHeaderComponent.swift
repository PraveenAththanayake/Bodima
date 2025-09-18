import SwiftUI

struct MapHeaderComponent: View {
    let habitationCount: Int
    let onResetLocation: () -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            headerTitle
            Spacer()
            headerButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Bodima")
                .font(.title2.bold())
                .foregroundStyle(AppColors.foreground)
            
            Text("Explore Places (\(habitationCount))")
                .font(.caption)
                .foregroundStyle(AppColors.mutedForeground)
        }
    }
    
    private var headerButtons: some View {
        HStack(spacing: 12) {
            resetLocationButton
            refreshButton
        }
    }
    
    private var resetLocationButton: some View {
        Button(action: onResetLocation) {
            Image(systemName: "location")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.foreground)
                .frame(width: 44, height: 44)
                .background(AppColors.input)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset view")
    }
    
    private var refreshButton: some View {
        Button(action: onRefresh) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.foreground)
                .frame(width: 44, height: 44)
                .background(AppColors.input)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Refresh")
    }
}

#Preview {
    MapHeaderComponent(
        habitationCount: 25,
        onResetLocation: {},
        onRefresh: {}
    )
}
