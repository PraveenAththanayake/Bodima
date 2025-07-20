import Foundation

// MARK: - User Stories Models

struct UserStoryData: Codable {
    let id: String
    let user: UserStoryUser
    let storyImageUrl: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case storyImageUrl
        case description
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

struct UserStoryUser: Codable {
    let id: String
    let auth: String?
    let firstName: String?
    let lastName: String?
    let bio: String?
    let phoneNumber: String?
    let addressNo: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let district: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case auth
        case firstName
        case lastName
        case bio
        case phoneNumber
        case addressNo
        case addressLine1
        case addressLine2
        case city
        case district
    }
}

// MARK: - Create Story Response Models (Simplified)

struct CreateUserStoryData: Codable {
    let id: String
    let user: String  // Just the user ID string
    let storyImageUrl: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let version: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case storyImageUrl
        case description
        case createdAt
        case updatedAt
        case version = "__v"
    }
}

// MARK: - Request Models

struct CreateUserStoryRequest: Codable {
    let user: String
    let description: String
    let storyImageUrl: String
}

// MARK: - Response Models

struct CreateUserStoryResponse: Codable {
    let success: Bool
    let message: String
    let data: CreateUserStoryData?
}

struct GetUserStoriesResponse: Codable {
    let success: Bool
    let data: [UserStoryData]
}

// MARK: - User Stories View Model

@MainActor
class UserStoriesViewModel: ObservableObject {
    @Published var userStories: [UserStoryData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Create story specific states
    @Published var isCreatingStory = false
    @Published var storyCreationSuccess = false
    @Published var storyCreationMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Fetch User Stories
    func fetchUserStories() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isLoading = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getUserStories,
            headers: headers,
            responseType: GetUserStoriesResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetUserStories success: \(response.success)")
                    print("🔍 DEBUG - GetUserStories data count: \(response.data.count)")
                    
                    if response.success {
                        self?.userStories = response.data
                        print("✅ User stories fetched successfully - Count: \(response.data.count)")
                    } else {
                        self?.showError("Failed to fetch user stories")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Network error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Create User Story
    func createUserStory(
        userId: String,
        description: String,
        storyImageUrl: String
    ) {
        guard !userId.isEmpty else {
            showStoryCreationError("User ID is required")
            return
        }
        
        guard !description.isEmpty else {
            showStoryCreationError("Story description is required")
            return
        }
        
        guard !storyImageUrl.isEmpty else {
            showStoryCreationError("Story image URL is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showStoryCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingStory = true
        clearStoryCreationError()
        
        let createStoryRequest = CreateUserStoryRequest(
            user: userId,
            description: description,
            storyImageUrl: storyImageUrl
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .createStories,
            body: createStoryRequest,
            headers: headers,
            responseType: CreateUserStoryResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingStory = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateStory success: \(response.success)")
                    print("🔍 DEBUG - CreateStory message: \(response.message)")
                    print("🔍 DEBUG - CreateStory data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.storyCreationSuccess = true
                        self?.storyCreationMessage = response.message
                        print("✅ User story created successfully")
                        
                        // Refresh the entire list to get the complete data with user objects
                        // Since the create response only contains user ID, we need to fetch
                        // the complete list to get the full user data
                        self?.fetchUserStories()
                        
                    } else {
                        self?.showStoryCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create story error: \(error)")
                    self?.handleStoryCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Refresh Stories
    func refreshUserStories() {
        fetchUserStories()
    }
    
    // MARK: - Error Handling
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showError(message)
                
            case .serverError(let message):
                showError("Server error: \(message)")
                
            default:
                showError(networkError.localizedDescription)
            }
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func handleStoryCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showStoryCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showStoryCreationError(message)
                
            case .serverError(let message):
                showStoryCreationError("Server error: \(message)")
                
            default:
                showStoryCreationError(networkError.localizedDescription)
            }
        } else {
            showStoryCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ User Stories Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    private func showStoryCreationError(_ message: String) {
        storyCreationMessage = message
        storyCreationSuccess = false
        print("❌ Story Creation Error: \(message)")
    }
    
    private func clearStoryCreationError() {
        storyCreationMessage = nil
        storyCreationSuccess = false
    }
    
    // MARK: - Utility Methods
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    func getRelativeTimeString(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return "Unknown time"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    func getUserDisplayName(from user: UserStoryUser) -> String {
        if let firstName = user.firstName, !firstName.isEmpty,
           let lastName = user.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        if let firstName = user.firstName, !firstName.isEmpty {
            return firstName
        }
        
        return "Unknown User"
    }
    
    func getUserLocation(from user: UserStoryUser) -> String {
        var locationComponents: [String] = []
        
        if let city = user.city, !city.isEmpty {
            locationComponents.append(city)
        }
        
        if let district = user.district, !district.isEmpty {
            locationComponents.append(district)
        }
        
        return locationComponents.isEmpty ? "Unknown Location" : locationComponents.joined(separator: ", ")
    }
    
    // MARK: - Computed Properties
    
    var storiesCount: Int {
        return userStories.count
    }
    
    var hasStories: Bool {
        return !userStories.isEmpty
    }
    
    var sortedStories: [UserStoryData] {
        return userStories.sorted { story1, story2 in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date1 = formatter.date(from: story1.createdAt),
                  let date2 = formatter.date(from: story2.createdAt) else {
                return false
            }
            
            return date1 > date2 // Most recent first
        }
    }
    
    // MARK: - Clear Data
    func clearStories() {
        userStories.removeAll()
        clearError()
        clearStoryCreationError()
    }
    
    // MARK: - Reset Story Creation State
    func resetStoryCreationState() {
        isCreatingStory = false
        storyCreationSuccess = false
        storyCreationMessage = nil
    }
    
    // MARK: - Story Management
    func removeStory(withId storyId: String) {
        userStories.removeAll { $0.id == storyId }
    }
    
    func getStory(withId storyId: String) -> UserStoryData? {
        return userStories.first { $0.id == storyId }
    }
}
