import UIKit

class ImageProcessor {
    func processProfileImage(_ image: UIImage?) -> String? {
        guard let image = image else { return nil }
        
        let resizedImage = resizeImage(image, targetSize: AuthConstants.profileImageSize)
        guard let imageData = resizedImage.jpegData(compressionQuality: AuthConstants.imageCompressionQuality) else {
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: targetSize)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}
