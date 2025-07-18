import Foundation

// MARK: - Habitation Image Models
struct HabitationImageData: Codable, Identifiable {
    let id: String
    let habitation: String
    let pictureUrl: String
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case pictureUrl
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

struct AddHabitationImageRequest: Codable {
    let habitation: String
    let pictureUrl: String
}

struct AddHabitationImageResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationImageData?
}

struct GetHabitationImagesResponse: Codable {
    let success: Bool
    let message: String
    let data: [HabitationImageData]?
}

// MARK: - Habitation Image ViewModel
@MainActor
class HabitationImageViewModel: ObservableObject {
    @Published var habitationImages: [HabitationImageData] = []
    @Published var selectedHabitationImages: [HabitationImageData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Add image specific states
    @Published var isAddingImage = false
    @Published var imageAdditionSuccess = false
    @Published var imageAdditionMessage: String?
    @Published var addedImage: HabitationImageData?
    
    // Fetch images specific states
    @Published var isFetchingImages = false
    @Published var fetchImagesError: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Add Habitation Image
    func addHabitationImage(
        habitationId: String,
        pictureUrl: String
    ) {
        guard !habitationId.isEmpty else {
            showImageAdditionError("Habitation ID is required")
            return
        }
        
        guard !pictureUrl.isEmpty else {
            showImageAdditionError("Picture URL is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showImageAdditionError("Authentication token not found. Please login again.")
            return
        }
        
        isAddingImage = true
        clearImageAdditionError()
        
        let addImageRequest = AddHabitationImageRequest(
            habitation: habitationId,
            pictureUrl: pictureUrl
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .addHabitaionImage(habitationId: habitationId),
            body: addImageRequest,
            headers: headers,
            responseType: AddHabitationImageResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAddingImage = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - AddHabitationImage success: \(response.success)")
                    print("🔍 DEBUG - AddHabitationImage message: \(response.message)")
                    print("🔍 DEBUG - AddHabitationImage data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.imageAdditionSuccess = true
                        self?.imageAdditionMessage = response.message
                        self?.addedImage = response.data
                        print("✅ Habitation image added successfully")
                        
                        // Add the new image to the list
                        if let newImage = response.data {
                            self?.habitationImages.append(newImage)
                            
                            // If this is for the currently selected habitation, add to selected images
                            if newImage.habitation == habitationId {
                                self?.selectedHabitationImages.append(newImage)
                            }
                        }
                    } else {
                        self?.showImageAdditionError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Add habitation image error: \(error)")
                    self?.handleImageAdditionError(error)
                }
            }
        }
    }
    
    // MARK: - Fetch Images for Habitation
    func fetchImagesForHabitation(habitationId: String) {
        guard !habitationId.isEmpty else {
            showError("Habitation ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isFetchingImages = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        // Note: This assumes there's a GET endpoint for fetching images by habitation ID
        // You might need to adjust this based on your actual API endpoint
        networkManager.requestWithHeaders(
            endpoint: .getHabitationById(habitationId: habitationId), // Modify if you have a specific images endpoint
            headers: headers,
            responseType: GetHabitationImagesResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isFetchingImages = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - GetHabitationImages success: \(response.success)")
                    print("🔍 DEBUG - GetHabitationImages data count: \(response.data?.count ?? 0)")
                    
                    if response.success {
                        self?.selectedHabitationImages = response.data ?? []
                        print("✅ Habitation images fetched successfully: \(self?.selectedHabitationImages.count ?? 0) items")
                    } else {
                        self?.showError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Fetch habitation images error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    func getImagesForHabitation(habitationId: String) -> [HabitationImageData] {
        return habitationImages.filter { $0.habitation == habitationId }
    }
    
    func getImageCount(for habitationId: String) -> Int {
        return getImagesForHabitation(habitationId: habitationId).count
    }
    
    func getFirstImageUrl(for habitationId: String) -> String? {
        return getImagesForHabitation(habitationId: habitationId).first?.pictureUrl
    }
    
    func removeImageFromList(imageId: String) {
        habitationImages.removeAll { $0.id == imageId }
        selectedHabitationImages.removeAll { $0.id == imageId }
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
    
    private func handleImageAdditionError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showImageAdditionError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showImageAdditionError(message)
                
            case .serverError(let message):
                showImageAdditionError("Server error: \(message)")
                
            default:
                showImageAdditionError(networkError.localizedDescription)
            }
        } else {
            showImageAdditionError("Network error: \(error.localizedDescription)")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Habitation Image Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    func showImageAdditionError(_ message: String) {
        imageAdditionMessage = message
        imageAdditionSuccess = false
        print("❌ Habitation Image Addition Error: \(message)")
    }
    
    private func clearImageAdditionError() {
        imageAdditionMessage = nil
        imageAdditionSuccess = false
    }
    
    // MARK: - Computed Properties
    var totalImageCount: Int {
        return habitationImages.count
    }
    
    var selectedHabitationImageCount: Int {
        return selectedHabitationImages.count
    }
    
    // MARK: - Date Formatting
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
    
    // MARK: - Clear Data
    func clearAllImages() {
        habitationImages.removeAll()
        selectedHabitationImages.removeAll()
        clearError()
        clearImageAdditionError()
    }
    
    func clearSelectedHabitationImages() {
        selectedHabitationImages.removeAll()
    }
    
    // MARK: - Reset States
    func resetImageAdditionState() {
        isAddingImage = false
        imageAdditionSuccess = false
        imageAdditionMessage = nil
        addedImage = nil
    }
}

// MARK: - HabitationImageViewModel Extension for Integration
extension HabitationImageViewModel {
    
    // Add image after creating a habitation
    func addImageToNewHabitation(
        habitationData: HabitationData,
        pictureUrl: String
    ) {
        addHabitationImage(
            habitationId: habitationData.id,
            pictureUrl: pictureUrl
        )
    }
    
    // Add multiple images to a habitation
    func addMultipleImages(
        habitationId: String,
        pictureUrls: [String]
    ) {
        for url in pictureUrls {
            addHabitationImage(habitationId: habitationId, pictureUrl: url)
        }
    }
    
    // Check if habitation has images
    func hasImages(for habitationId: String) -> Bool {
        return !getImagesForHabitation(habitationId: habitationId).isEmpty
    }
    
    // Get image URLs for a habitation
    func getImageUrls(for habitationId: String) -> [String] {
        return getImagesForHabitation(habitationId: habitationId).map { $0.pictureUrl }
    }
}

