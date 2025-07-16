import SwiftUI
import PhotosUI

// MARK: - Create Profile View (Placeholder)
struct CreateProfileView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Complete Your Profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                    .padding(.top, 32)
                
                Text("Please provide your basic information to complete your profile.")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Profile Image
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.primary.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "camera")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppColors.primary)
                            )
                    }
                }
                .disabled(authViewModel.isLoading)
                
                VStack(spacing: 16) {
                    // First Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                        
                        TextField("Enter your first name", text: $firstName)
                            .font(.system(size: 17))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.border, lineWidth: 0.5)
                                    )
                            )
                            .disabled(authViewModel.isLoading)
                    }
                    
                    // Last Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                        
                        TextField("Enter your last name", text: $lastName)
                            .font(.system(size: 17))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.border, lineWidth: 0.5)
                                    )
                            )
                            .disabled(authViewModel.isLoading)
                    }
                }
                .padding(.horizontal, 24)
                
                // Complete Profile Button
                Button(action: {
                    authViewModel.createProfile(
                        firstName: firstName,
                        lastName: lastName,
                        profileImage: profileImage
                    )
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryForeground))
                                .scaleEffect(0.9)
                                .padding(.trailing, 8)
                        }
                        
                        Text(authViewModel.isLoading ? "Creating Profile..." : "Complete Profile")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.primaryForeground)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(authViewModel.isLoading ? AppColors.primary.opacity(0.6) : AppColors.primary)
                    )
                }
                .disabled(authViewModel.isLoading || firstName.isEmpty || lastName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Alert Message Display
                if let alertMessage = authViewModel.alertMessage {
                    AlertBanner(message: alertMessage) {
                        authViewModel.clearAlert()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
    }
}
#Preview {
    CreateProfileView()
}
