import SwiftUI
import PhotosUI

struct CreateProfileView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var phoneNumber = ""
    @State private var addressNo = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var district = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var profileImageURL = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Complete Your Profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("Please provide your information to complete your profile.")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    
                    // Profile Image Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.primary, lineWidth: 3)
                                    )
                            } else {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppColors.primary)
                                            Text("Add Photo")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppColors.primary)
                                        }
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                AppColors.primary.opacity(0.3),
                                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                            )
                                            .scaleEffect(1.1)
                                    )
                            }
                        }
                        .disabled(profileViewModel.isCreatingProfile)
                        
                        Text("Tap to add profile photo")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Basic Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            HStack(spacing: 12) {
                                // First Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("First Name *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    TextField("First name", text: $firstName)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .disabled(profileViewModel.isCreatingProfile)
                                }
                                
                                // Last Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Last Name *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    TextField("Last name", text: $lastName)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .disabled(profileViewModel.isCreatingProfile)
                                }
                            }
                            
                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle(minHeight: 80))
                                    .disabled(profileViewModel.isCreatingProfile)
                            }
                        }
                        
                        // Contact Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            // Phone Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number *")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                TextField("e.g., +94775541417", text: $phoneNumber)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.phonePad)
                                    .disabled(profileViewModel.isCreatingProfile)
                            }
                        }
                        
                        // Address Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Address Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            // Address No
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address No *")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                TextField("e.g., NO 34/1", text: $addressNo)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .disabled(profileViewModel.isCreatingProfile)
                            }
                            
                            // Address Line 1
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address Line 1 *")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                TextField("e.g., Pansala Udaha", text: $addressLine1)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .disabled(profileViewModel.isCreatingProfile)
                            }
                            
                            // Address Line 2
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address Line 2")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                TextField("e.g., Welhena", text: $addressLine2)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .disabled(profileViewModel.isCreatingProfile)
                            }
                            
                            HStack(spacing: 12) {
                                // City
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("City *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    TextField("e.g., Minuwangoda", text: $city)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .disabled(profileViewModel.isCreatingProfile)
                                }
                                
                                // District
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("District *")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    TextField("e.g., Gampaha", text: $district)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .disabled(profileViewModel.isCreatingProfile)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Complete Profile Button
                    Button(action: {
                        createProfile()
                    }) {
                        HStack {
                            if profileViewModel.isCreatingProfile {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryForeground))
                                    .scaleEffect(0.9)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(profileViewModel.isCreatingProfile ? "Creating Profile..." : "Complete Profile")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppColors.primaryForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(profileViewModel.isCreatingProfile ? AppColors.primary.opacity(0.6) : AppColors.primary)
                        )
                    }
                    .disabled(profileViewModel.isCreatingProfile || !isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Required fields note
                    Text("* Required fields")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.horizontal, 24)
                    
                    // Error Message Display
                    if let errorMessage = profileViewModel.profileCreationMessage, !profileViewModel.profileCreationSuccess {
                        AlertBanner(message: AlertMessage.error(errorMessage), onDismiss: {
                            profileViewModel.resetProfileCreationState()
                        })                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .alert("Success!", isPresented: $showingSuccessAlert) {
                Button("Continue") {
                    // Handle success - maybe navigate to main app
                    profileViewModel.resetProfileCreationState()
                }
            } message: {
                Text(profileViewModel.profileCreationMessage ?? "Profile created successfully!")
            }
            .onChange(of: profileViewModel.profileCreationSuccess) { success in
                if success {
                    showingSuccessAlert = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        !addressNo.trimmingCharacters(in: .whitespaces).isEmpty &&
        !addressLine1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !district.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Methods
    private func createProfile() {
        // Get user ID from auth or UserDefaults
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            profileViewModel.showProfileCreationError("User ID not found. Please login again.")
            return
        }
        
        // Process profile image if available
        var processedImageURL = ""
        if profileImage != nil {
            processedImageURL = "https://example.com/profile-pic.jpg"
        }
        
        // Create the profile using ProfileViewModel
        profileViewModel.createProfile(
            userId: userId,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            profileImageURL: processedImageURL,
            bio: bio.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
            addressNo: addressNo.trimmingCharacters(in: .whitespaces),
            addressLine1: addressLine1.trimmingCharacters(in: .whitespaces),
            addressLine2: addressLine2.trimmingCharacters(in: .whitespaces),
            city: city.trimmingCharacters(in: .whitespaces),
            district: district.trimmingCharacters(in: .whitespaces)
        )
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    let minHeight: CGFloat
    
    init(minHeight: CGFloat = 50) {
        self.minHeight = minHeight
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 0.5)
                    )
            )
    }
}


#Preview {
    CreateProfileView()
}
