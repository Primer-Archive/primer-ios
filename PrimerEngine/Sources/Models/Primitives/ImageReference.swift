import SwiftUI
import UIKit.UIImage


public enum ImageReference: Hashable {

    case named(name: String, bundle: Bundle)
    case path(String)
    
    public init(name: String, bundle: Bundle = .main) {
        self = .named(name: name, bundle: bundle)
    }

    public var swiftUIImage: Image? {
        if let image = uiImage {
            return Image(uiImage: image)
        } else {
            return nil
        }
    }

    public var uiImage: UIImage? {
        switch self {
        case .named(name: let name, bundle: let bundle):
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        case .path(let path):
            return UIImage(contentsOfFile: path)
        }
    }

}
