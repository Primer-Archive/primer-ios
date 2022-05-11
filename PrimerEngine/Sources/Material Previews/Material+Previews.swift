import SceneKit
import SwiftUI
import CoreGraphics
import AVFoundation
import UIKit


//extension Material {
//    
//    public var previewView: some View {
//        return RendererView(material: self)
//    }
//    
//}
//
//
//fileprivate struct RendererView: View {
//    
//    var material: Material
//    
//    @State private var content: AnyView? = nil
//    
//    var body: some View {
//        ZStack {
//            content
//        }
//        .onAppear(perform: self.load)
//    }
//    
//    private func load() {
//        guard self.content == nil else { return }
//        
//        switch material.diffuse.contents {
//        case .color(let color):
//            self.content = AnyView(color.swiftUIColor)
//        case .constant(let value):
//            self.content = AnyView(SwiftUI.Color(white: value))
//        case .texture(let reference):
//            DispatchQueue.global().async {
//                guard let image = reference.uiImage else {
//                    DispatchQueue.main.async {
//                        self.content = AnyView(SwiftUI.Color.gray)
//                    }
//                    return
//                }
//                let resized = image.smallestDimension(length: 200)
//                let imageView = Image(uiImage: resized)
//                    .interpolation(.high)
//                    .antialiased(true)
//                    .resizable()
//                    .equatable()
//                    .aspectRatio(contentMode: .fill)
//                DispatchQueue.main.async {
//                    self.content = AnyView(imageView)
//                }
//            }
//        case .none:
//            self.content = AnyView(EmptyView())
//        }
//    }
//}

//
//.resizable()
//.antialiased(true)
//.interpolation(.high)
//.aspectRatio(contentMode: .fill)


extension UIImage {
    
    fileprivate func smallestDimension(length: CGFloat) -> UIImage {
        let minDimension: CGFloat = min(size.width, size.height)
        let scale = min(length / minDimension, 1.0)
        let scaledSize = CGSize(
            width: size.width * scale,
            height: size.height * scale)
        return aspectFill(size: scaledSize)
    }
    
    fileprivate func aspectFill(size: CGSize) -> UIImage {
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        
        let selfAspectRatio = self.size.width / self.size.height
        let outputAspectRatio = size.width / size.height
        
        let outputRect: CGRect
        
        if selfAspectRatio > outputAspectRatio {
            // Self is wider
            outputRect = CGRect(
                x: (size.width - size.height*selfAspectRatio) / 2.0,
                y: 0.0,
                width: size.height * selfAspectRatio,
                height: size.height)
        } else {
            // Self is taller
            outputRect = CGRect(
                x: 0.0,
                y: (size.height - size.width/selfAspectRatio) / 2.0,
                width: size.width,
                height: size.width / selfAspectRatio)
        }
                
        let image = UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                self.draw(in: outputRect)
            }
        
        return image
    }
    
    
}

