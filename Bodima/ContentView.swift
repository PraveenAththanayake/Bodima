import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .idle:
                // Show loading or splash screen while checking auth status
                LoadingView()
                
            case .unauthenticated:
                // Show authentication flow
                AuthenticationView()
                
            case .authenticated:
                // Check if token is valid before showing authenticated content
                Group {
                    if authViewModel.isTokenExpired() {
                        // Force logout if token is expired and show authentication view
                        let _ = DispatchQueue.main.async {
                            authViewModel.forceSignOut()
                        }
                        // Show authentication view while logging out
                        AuthenticationView()
                    }
                    else if authViewModel.needsProfileCompletion {
                        // Check if user needs to complete profile
                        CreateProfileView()
                    } else {
                        // Show main app content
                        MainAppView()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState.id)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Authentication View (NavigationView instead of TabView)
struct AuthenticationView: View {
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if showingSignUp {
                    SignUpView()
                        .transition(.move(edge: .trailing))
                } else {
                    SignInView()
                        .transition(.move(edge: .leading))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingSignUp)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Updated SignInView with navigation
struct MainAppView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        TabView {
            HomeView(profileId: profileViewModel.userProfile?.id ?? "")
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            MapView(profileId: profileViewModel.userProfile?.id ?? "")
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            PostPlaceView()
                .tabItem {
                    Label("Post", systemImage: "plus.circle")
                }
            
            MyHabitationsView()
                .tabItem {
                    Label("My Places", systemImage: "house.fill")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            NotificationsView()
                .tabItem {
                    Label("Notification", systemImage: "bell")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .onAppear {
            loadProfileForMainApp()
        }
    }
    
    private func loadProfileForMainApp() {
        // Check if token is valid before loading profile
        if authViewModel.isTokenExpired() {
            // Force logout if token is expired
            DispatchQueue.main.async {
                authViewModel.forceSignOut()
            }
            return
        }
        
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        // Load profile data for MainAppView's ProfileViewModel
        profileViewModel.fetchUserProfile(userId: userId)
    }
}



// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("App Settings") {
                    HStack {
                        Image(systemName: "bell")
                        Text("Notifications")
                    }
                    
                    HStack {
                        Image(systemName: "moon")
                        Text("Dark Mode")
                    }
                }
                
                Section("Support") {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Help & Support")
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                        Text("Contact Us")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}





// MARK: - Alert Banner Component
struct AlertBanner: View {
    let message: AlertMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
            
            Text(message.message)
                .font(.system(size: 15))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: message.type)
    }
    
    private var iconName: String {
        switch message.type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch message.type {
        case .success:
            return .green
        case .error:
            return AppColors.destructive
        case .warning:
            return .orange
        case .info:
            return AppColors.primary
        }
    }
    
    private var textColor: Color {
        switch message.type {
        case .success:
            return .green
        case .error:
            return AppColors.destructive
        case .warning:
            return .orange
        case .info:
            return AppColors.primary
        }
    }
    
    private var backgroundColor: Color {
        switch message.type {
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return AppColors.destructive.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .info:
            return AppColors.primary.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch message.type {
        case .success:
            return Color.green.opacity(0.3)
        case .error:
            return AppColors.destructive.opacity(0.3)
        case .warning:
            return Color.orange.opacity(0.3)
        case .info:
            return AppColors.primary.opacity(0.3)
        }
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? AppColors.primary : AppColors.mutedForeground)
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                    .padding(.top, 32)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                    
                    TextField("Enter your email", text: $email)
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
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    // Handle password reset
                    dismiss()
                }) {
                    Text("Send Reset Link")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.primaryForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.primary)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Image Picker (Placeholder)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
