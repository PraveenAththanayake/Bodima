import SwiftUI

// Profile image section component with avatar, name, and status display
// Handles async image loading with fallback to initials and profile completion status
struct ProfileImageSectionComponent: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile avatar with image or initials fallback
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                
                if let imageURL = profile.profileImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        ProfileInitialsComponent(profile: profile)
                    }
                } else {
                    ProfileInitialsComponent(profile: profile)
                }
            }
            .accessibilityLabel("Profile picture")
            
            // User name and username display
            VStack(spacing: 4) {
                Text(profileViewModel.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("@\(profile.auth.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Profile completion status badge
            ProfileStatusBadgeComponent(isComplete: profileViewModel.isProfileComplete)
        }
        .padding(.top, 20)
    }
}

// Profile initials display component for avatar fallback
// Shows first letter of username with proper styling
struct ProfileInitialsComponent: View {
    let profile: ProfileData
    
    var body: some View {
        Text(profile.auth.username.prefix(1).uppercased())
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(AppColors.foreground)
            .accessibilityLabel("Profile initials: \(profile.auth.username.prefix(1).uppercased())")
    }
}

// Profile completion status badge with dynamic styling
// Provides visual feedback on profile completeness with appropriate colors
struct ProfileStatusBadgeComponent: View {
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isComplete ? .green : .orange)
            
            Text(isComplete ? "Profile Complete" : "Profile Incomplete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isComplete ? .green : .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill((isComplete ? Color.green : Color.orange).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isComplete ? .green : .orange, lineWidth: 1)
                )
        )
        .accessibilityLabel(isComplete ? "Profile is complete" : "Profile needs completion")
    }
}

#Preview {
    // Preview would require ProfileData mock
    Text("ProfileImageSectionComponent Preview")
}
