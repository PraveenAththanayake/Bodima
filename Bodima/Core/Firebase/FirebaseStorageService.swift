import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage().reference()
    
    private init() {}
    
    /// Uploads an image to Firebase Storage and returns the download URL
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - path: The storage path (e.g., "habitation_images/")
    ///   - filename: Optional custom filename, defaults to UUID
    ///   - completion: Callback with result containing download URL or error
    func uploadImage(
        _ image: UIImage,
        folderPath: String = "habitation_images",
        filename: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Resize image before uploading to reduce file size
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 1200, height: 1200))
        
        // Use higher compression to reduce file size
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            completion(.failure(StorageError.imageConversionFailed))
            return
        }
        
        let imageName = filename ?? UUID().uuidString
        let imageRef = storage.child(folderPath).child("\(imageName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    completion(.failure(StorageError.downloadURLMissing))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    /// Uploads multiple images to Firebase Storage and returns all download URLs
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - path: The storage path (e.g., "habitation_images/")
    ///   - progressHandler: Optional callback to track upload progress (0.0 to 1.0)
    ///   - completion: Callback with result containing array of download URLs or error
    func uploadMultipleImages(
        _ images: [UIImage],
        folderPath: String = "habitation_images",
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        guard !images.isEmpty else {
            completion(.success([]))
            return
        }
        
        var uploadedURLs: [String] = []
        var uploadedCount = 0
        let totalImages = images.count
        
        for (index, image) in images.enumerated() {
            // Resize image before uploading to reduce file size
            let resizedImage = resizeImage(image, targetSize: CGSize(width: 1200, height: 1200))
            
            uploadImage(resizedImage, folderPath: folderPath) { result in
                switch result {
                case .success(let url):
                    uploadedURLs.append(url)
                    uploadedCount += 1
                    
                    // Report progress
                    let progress = Double(uploadedCount) / Double(totalImages)
                    progressHandler?(progress)
                    
                    // Check if all uploads are complete
                    if uploadedCount == totalImages {
                        completion(.success(uploadedURLs))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
            }
        }
    }
    
    /// Deletes an image from Firebase Storage
    /// - Parameters:
    ///   - url: The download URL of the image to delete
    ///   - completion: Callback with success or error
    func deleteImage(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let urlObj = URL(string: url),
              let imagePath = urlObj.path.components(separatedBy: "/o/").last?.removingPercentEncoding,
              let decodedPath = imagePath.removingPercentEncoding?.replacingOccurrences(of: "/", with: "%2F") else {
            completion(.failure(StorageError.invalidURL))
            return
        }
        
        storage.child(decodedPath).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

enum StorageError: Error {
    case imageConversionFailed
    case downloadURLMissing
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .downloadURLMissing:
            return "Failed to get download URL"
        case .invalidURL:
            return "Invalid storage URL format"
        }
    }
}

// MARK: - Image Utilities
extension FirebaseStorageService {
    /// Resizes an image to the target size while maintaining aspect ratio
    /// - Parameters:
    ///   - image: The original UIImage
    ///   - targetSize: The target size to resize to
    /// - Returns: A resized UIImage
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        // Check if resizing is needed
        let size = image.size
        
        // If image is smaller than target size, return original
        if size.width <= targetSize.width && size.height <= targetSize.height {
            return image
        }
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to ensure the image fits within the target size
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledWidth = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor
        let targetRect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        
        // Render the resized image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scaledWidth, height: scaledHeight), false, 0)
        image.draw(in: targetRect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}