import SwiftUI

struct MapLoadingComponent: View {
    let isLoading: Bool
    
    var body: some View {
        Group {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading habitations...")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .shadow(color: AppColors.border.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    MapLoadingComponent(isLoading: true)
}
