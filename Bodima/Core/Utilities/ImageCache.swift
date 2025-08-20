import Foundation
import SwiftUI

/// A cache that stores images in memory and on disk
class ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up the cache directory in the app's document directory
        let documentsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsDirectory.appendingPathComponent("imageCache")
        
        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
        
        // Set memory cache limits
        memoryCache.countLimit = 100 // Maximum number of images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Register for memory warning notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Get an image from the cache
    /// - Parameter url: The URL of the image
    /// - Returns: The cached image if available, nil otherwise
    func getImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key as String)
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Store in memory cache for faster access next time
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    /// Store an image in the cache
    /// - Parameters:
    ///   - image: The image to store
    ///   - url: The URL associated with the image
    func storeImage(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key)
        
        // Store in disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key as String)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    /// Remove an image from the cache
    /// - Parameter url: The URL of the image to remove
    func removeImage(for url: URL) {
        let key = cacheKey(for: url)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key)
        
        // Remove from disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key as String)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Clear all images from the memory cache
    @objc func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /// Clear all images from the disk cache
    func clearDiskCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing disk cache: \(error)")
        }
    }
    
    /// Generate a unique cache key for a URL
    /// - Parameter url: The URL to generate a key for
    /// - Returns: A unique key for the URL
    private func cacheKey(for url: URL) -> NSString {
        let urlString = url.absoluteString
        return urlString.replacingOccurrences(of: "/", with: "_") as NSString
    }
}

/// A SwiftUI Image view that loads images from a URL with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        if let url = url {
            if let cachedImage = ImageCache.shared.getImage(for: url) {
                content(Image(uiImage: cachedImage))
            } else {
                AsyncImage(
                    url: url,
                    scale: scale,
                    transaction: transaction
                ) { phase in
                    switch phase {
                    case .empty:
                        placeholder()
                    case .success(let image):
                        content(image)
                    case .failure:
                        placeholder()
                    @unknown default:
                        placeholder()
                    }
                }
            }
        } else {
            placeholder()
        }
    }
    
    /// Convert a SwiftUI Image to UIImage
    private func imageToUIImage(_ image: Image) -> UIImage? {
        let renderer = ImageRenderer(content: image.resizable())
        return renderer.uiImage
    }
}

/// Convenience initializers for CachedAsyncImage
extension CachedAsyncImage {
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction()
    ) {
        self.init(
            url: url,
            scale: scale,
            transaction: transaction,
            content: { image in
                image as! Content
            },
            placeholder: { 
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 100) as! Placeholder
            }
        )
    }
}