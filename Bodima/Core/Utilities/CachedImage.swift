import SwiftUI
import UIKit

/// A SwiftUI view that displays an image from a URL with caching
struct CachedImage<Placeholder: View>: View {
    let url: String?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    init(
        url: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard !isLoading, let urlString = url, let url = URL(string: urlString) else { return }
        
        // Check if image is in cache
        if let cachedImage = ImageCache.shared.getImage(for: url) {
            self.image = cachedImage
            return
        }
        
        // If not in cache, download it
        isLoading = true
        
        // Create a URLRequest with cache policy
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { isLoading = false }
            
            guard let data = data, let downloadedImage = UIImage(data: data) else {
                print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Resize large images to reduce memory usage
            let processedImage = self.processImageForCache(downloadedImage)
            
            // Store in cache
            ImageCache.shared.storeImage(processedImage, for: url)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.image = processedImage
            }
        }.resume()
    }
    
    /// Process an image for caching by resizing if needed
    /// - Parameter image: The original UIImage
    /// - Returns: A processed UIImage suitable for caching
    private func processImageForCache(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200 // Maximum dimension for cached images
        let imageSize = image.size
        
        // If image is already smaller than max dimension, return it as is
        if imageSize.width <= maxDimension && imageSize.height <= maxDimension {
            return image
        }
        
        // Calculate scale factor to resize the image
        let widthRatio = maxDimension / imageSize.width
        let heightRatio = maxDimension / imageSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newWidth = imageSize.width * scaleFactor
        let newHeight = imageSize.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Create a new context and draw the resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
     }
}

/// A convenience initializer for CachedImage with a progress view placeholder
extension CachedImage {
    init(url: String?, contentMode: ContentMode = .fill) {
        self.init(url: url, contentMode: contentMode) {
            ProgressView()
                .frame(minWidth: 44, minHeight: 44)
                .aspectRatio(contentMode: .fit) as! Placeholder
        }
    }
    
    init(url: String?, contentMode: ContentMode = .fill, systemName: String) {
        self.init(url: url, contentMode: contentMode) {
            Image(systemName: systemName)
                .font(.system(size: 44, weight: .light))
                .foregroundColor(.gray)
                .frame(minWidth: 44, minHeight: 44)
                .aspectRatio(contentMode: .fit) as! Placeholder
        }
    }
}