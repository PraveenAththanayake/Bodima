import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileViewModel: ProfileViewModel
    @StateObject private var authViewModel = AuthViewModel.shared
    
    // Form fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var bio: String = ""
    @State private var phoneNumber: String = ""
    @State private var addressNo: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var district: String = ""
    @State private var profileImageURL: String = ""
    
    // UI State
    @State private var isUpdating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    EditProfileImageSection(profileImageURL: $profileImageURL)
                    
                    // Personal Information Section
                    EditProfileSection(title: "Personal Information") {
                        VStack(spacing: 16) {
                            EditProfileTextField(
                                title: "First Name",
                                text: $firstName,
                                placeholder: "Enter your first name"
                            )
                            
                            EditProfileTextField(
                                title: "Last Name",
                                text: $lastName,
                                placeholder: "Enter your last name"
                            )
                            
                            EditProfileTextField(
                                title: "Phone Number",
                                text: $phoneNumber,
                                placeholder: "Enter your phone number",
                                keyboardType: .phonePad
                            )
                            
                            EditProfileTextEditor(
                                title: "Bio",
                                text: $bio,
                                placeholder: "Tell us about yourself..."
                            )
                        }
                    }
                    
                    // Address Information Section
                    EditProfileSection(title: "Address Information") {
                        VStack(spacing: 16) {
                            EditProfileTextField(
                                title: "Address No",
                                text: $addressNo,
                                placeholder: "House/Building number"
                            )
                            
                            EditProfileTextField(
                                title: "Address Line 1",
                                text: $addressLine1,
                                placeholder: "Street address"
                            )
                            
                            EditProfileTextField(
                                title: "Address Line 2",
                                text: $addressLine2,
                                placeholder: "Apartment, suite, etc. (optional)"
                            )
                            
                            EditProfileTextField(
                                title: "City",
                                text: $city,
                                placeholder: "Enter your city"
                            )
                            
                            EditProfileTextField(
                                title: "District",
                                text: $district,
                                placeholder: "Enter your district"
                            )
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Save Button
                        Button(action: saveProfile) {
                            HStack(spacing: 8) {
                                if isUpdating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                
                                Text(isUpdating ? "Updating..." : "Save Changes")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isUpdating || !isFormValid)
                        
                        // Cancel Button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.input)
                                .cornerRadius(12)
                        }
                        .disabled(isUpdating)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            loadCurrentProfileData()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Success" {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentProfileData() {
        guard let profile = profileViewModel.userProfile else { return }
        
        firstName = profile.firstName ?? ""
        lastName = profile.lastName ?? ""
        bio = profile.bio ?? ""
        phoneNumber = profile.phoneNumber ?? ""
        addressNo = profile.addressNo ?? ""
        addressLine1 = profile.addressLine1 ?? ""
        addressLine2 = profile.addressLine2 ?? ""
        city = profile.city ?? ""
        district = profile.district ?? ""
        profileImageURL = profile.profileImageURL ?? ""
    }
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveProfile() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            showAlert(title: "Error", message: "User ID not found. Please login again.")
            return
        }
        
        isUpdating = true
        
        profileViewModel.updateProfile(
            userId: userId,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            profileImageURL: profileImageURL.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            addressNo: addressNo.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine1: addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine2: addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            district: district.trimmingCharacters(in: .whitespacesAndNewlines)
        ) { [self] success, message in
            DispatchQueue.main.async {
                isUpdating = false
                if success {
                    showAlert(title: "Success", message: message ?? "Profile updated successfully!")
                } else {
                    showAlert(title: "Error", message: message ?? "Failed to update profile. Please try again.")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Edit Profile Image Section
struct EditProfileImageSection: View {
    @Binding var profileImageURL: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image Preview
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                
                if !profileImageURL.isEmpty, let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "camera")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .offset(x: -8, y: -8)
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            // Profile Image URL Field
            EditProfileTextField(
                title: "Profile Image URL",
                text: $profileImageURL,
                placeholder: "Enter image URL (optional)"
            )
        }
    }
}

// MARK: - Edit Profile Section
struct EditProfileSection<Content: View>: View {
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
    }
}

// MARK: - Edit Profile Text Field
struct EditProfileTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.input)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .keyboardType(keyboardType)
        }
    }
}

// MARK: - Edit Profile Text Editor
struct EditProfileTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 100)
                    .background(AppColors.input)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    EditProfileView(profileViewModel: ProfileViewModel())
}
