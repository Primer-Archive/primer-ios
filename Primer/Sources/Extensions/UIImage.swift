import UIKit

extension UIImage {
    func resize(_ maxSize: CGFloat) -> UIImage {
        // adjust for device pixel density
        let maxSizePixels = maxSize / UIScreen.main.scale
        // work out aspect ratio
        let aspectRatio =  size.width/size.height
        // variables for storing calculated data
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        if aspectRatio > 1 {
            // landscape
            width = maxSizePixels
            height = maxSizePixels / aspectRatio
        } else {
            // portrait
            height = maxSizePixels
            width = maxSizePixels * aspectRatio
        }
        // create an image renderer of the correct size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: UIGraphicsImageRendererFormat.default())
        // render the image
        newImage = renderer.image {
            (context) in
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        // return the image
        return newImage
    }
} 
