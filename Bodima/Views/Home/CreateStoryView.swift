import SwiftUI
import UIKit

struct CreateStoryView: View {
    @ObservedObject var viewModel: UserStoriesViewModel
    @ObservedObject var profileViewModel = ProfileViewModel()
    let userId: String
    @Binding var isPresented: Bool
    @State private var description: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var isUploadingImage = false
    @State private var uploadProgress: Double = 0.0
    
    // Extract gradient as computed property to reduce compiler complexity
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.2, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var buttonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.4, blue: 0.9)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var imageSelectionGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var textEditorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.04)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Image Selection Section
                    imageSelectionSection
                    
                    // Description Section
                    descriptionSection
                    
                    // Error Message
                    errorMessageView
                    
                    // Post Button
                    postButton
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Select Photo"),
                message: Text("Choose how you'd like to add a photo"),
                buttons: [
                    .default(Text("Photo Library")) {
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: viewModel.storyCreationSuccess) { success in
            if success {
                isPresented = false
                viewModel.resetStoryCreationState()
                // Reset form
                selectedImage = nil
                description = ""
                isUploadingImage = false
                uploadProgress = 0.0
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            Text("Create Story")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Add Photo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            Button(action: {
                showImagePicker = true
            }) {
                imageSelectionContent
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var imageSelectionContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(imageSelectionGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(height: 200)
            
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(20)
            } else {
                emptyImagePlaceholder
            }
            
            // Upload progress overlay
            if isUploadingImage {
                VStack(spacing: 12) {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 200)
                    
                    Text("Uploading image... \(Int(uploadProgress * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
            }
        }
    }
    
    private var emptyImagePlaceholder: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("Tap to add photo")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Choose from gallery or take a new photo")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    private var descriptionSection: some View {
        VStack(spacing: 16) {
            Text("Add Description")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(textEditorGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 100)
                
                TextEditor(text: $description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .frame(minHeight: 100)
                    .padding(16)
                
                if description.isEmpty {
                    Text("Tell your story...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 24)
                        .padding(.leading, 20)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = viewModel.storyCreationMessage, !viewModel.storyCreationSuccess {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var postButton: some View {
        Button(action: {
            createStory()
        }) {
            HStack(spacing: 8) {
                if viewModel.isCreatingStory || isUploadingImage {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(getButtonText())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if canPostStory && !isUploadingImage {
                        buttonGradient
                    } else {
                        Color.white.opacity(0.2)
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .disabled(!canPostStory || viewModel.isCreatingStory || isUploadingImage)
        .scaleEffect(canPostStory && !isUploadingImage ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canPostStory)
    }
    
    private var canPostStory: Bool {
        selectedImage != nil && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func getButtonText() -> String {
        if isUploadingImage {
            return "Uploading..."
        } else if viewModel.isCreatingStory {
            return "Posting..."
        } else {
            return "Post Story"
        }
    }
    
    // MARK: - Story Creation Logic
    
    private func createStory() {
        guard let selectedImage = selectedImage else {
            viewModel.storyCreationMessage = "No image selected"
            viewModel.storyCreationSuccess = false
            return
        }
        
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.storyCreationMessage = "Description cannot be empty"
            viewModel.storyCreationSuccess = false
            return
        }
        
        let userIdToUse = getUserId()
        guard !userIdToUse.isEmpty else {
            viewModel.storyCreationMessage = "User ID is missing"
            viewModel.storyCreationSuccess = false
            return
        }
        
        // Start the upload process
        uploadImageAndCreateStory(image: selectedImage, userId: userIdToUse)
    }
    
    private func uploadImageAndCreateStory(image: UIImage, userId: String) {
        isUploadingImage = true
        uploadProgress = 0.0
        
        // Upload image to Firebase Storage with progress tracking
        FirebaseStorageService.shared.uploadImage(
            image,
            folderPath: "story_images",
            filename: "story_\(userId)_\(Date().timeIntervalSince1970)"
        ) { result in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.uploadProgress = 1.0
                
                switch result {
                case .success(let imageUrl):
                    // Create the story with the uploaded image URL
                    self.viewModel.createUserStory(
                        userId: userId,
                        description: self.description,
                        storyImageUrl: imageUrl
                    )
                    
                case .failure(let error):
                    self.viewModel.storyCreationMessage = "Failed to upload image: \(error.localizedDescription)"
                    self.viewModel.storyCreationSuccess = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get user ID from various possible sources
    private func getUserId() -> String {
        // Option 1: Try to get from the passed userId parameter
        if !userId.isEmpty {
            return userId
        }
        
        // Option 2: Try to get from profile data
        if let profileId = profileViewModel.userProfile?.id {
            return profileId
        }
        
        // Option 3: Try to get from auth data within profile
        if let authId = profileViewModel.userProfile?.auth.id {
            return authId
        }
        
        // Option 4: Try to get from UserDefaults
        if let storedUserId = UserDefaults.standard.string(forKey: "user_id") {
            return storedUserId
        }
        
        return ""
    }
}
