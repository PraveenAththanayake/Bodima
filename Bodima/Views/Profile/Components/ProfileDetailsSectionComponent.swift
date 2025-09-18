import SwiftUI

// Profile details section component with organized information cards
// Displays personal, address, security, and account information in structured layout
struct ProfileDetailsSectionComponent: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Personal information card with user details
            ProfileCardComponent(title: "Personal Information") {
                VStack(spacing: 12) {
                    ProfileDetailRowComponent(title: "User ID", value: profile.id ?? "Not provided")
                    ProfileDetailRowComponent(title: "Last Name", value: profile.lastName ?? "Not provided")
                    ProfileDetailRowComponent(title: "Email", value: profile.auth.email)
                    ProfileDetailRowComponent(title: "Phone", value: profile.phoneNumber ?? "Not provided")
                    
                    if let bio = profile.bio, !bio.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bio:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            Text(bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Address information card
            ProfileCardComponent(title: "Address Information") {
                VStack(spacing: 12) {
                    ProfileDetailRowComponent(title: "Address", value: profileViewModel.fullAddress)
                }
            }
            
            // Security settings integration
            ProfileSecurityComponent()
            
            // Account metadata and timestamps
            ProfileCardComponent(title: "Account Information") {
                VStack(spacing: 12) {
                    ProfileDetailRowComponent(title: "User ID", value: profile.id)
                    ProfileDetailRowComponent(title: "Username", value: profile.auth.username)
                    ProfileDetailRowComponent(title: "Created", value: profileViewModel.formatDate(profile.createdAt))
                    ProfileDetailRowComponent(title: "Last Updated", value: profileViewModel.formatDate(profile.updatedAt))
                }
            }
        }
    }
}

// Reusable card container component for profile sections
// Provides consistent styling and layout for information groups
struct ProfileCardComponent<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

// Individual detail row component for key-value pairs
// Provides consistent formatting for profile information display
struct ProfileDetailRowComponent: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    Text("ProfileDetailsSectionComponent Preview")
}
