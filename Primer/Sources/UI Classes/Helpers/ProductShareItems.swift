//
//  ProductShareItems.swift
//  Primer
//
//  Created by Sarah Hurtgen on 2/24/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import UIKit
import PrimerEngine

// MARK: - Controller

class ProductShareActivityController: UIActivityViewController {
    init(product: ProductModel, image: UIImage? = nil) {
        super.init(activityItems: [ProductStringItemSource(product: product), ProductImageItemSource(image: image)], applicationActivities: nil)
    }
}

// MARK: - Image Item

class ProductImageItemSource: NSObject, UIActivityItemSource {
    var image: UIImage?
    init(image: UIImage?) {
        self.image = image
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image ?? UIImage()
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        
        // excludes text from image since the link preview already expands
        if activityType != .message {
            return image
        } else {
            return nil
        }
    }
}

// MARK: - String Item

class ProductStringItemSource: NSObject, UIActivityItemSource {
    var product: ProductModel
    var subject: String
    var urlString: String
    var message: String
    
    init(product: ProductModel) {
        self.product = product
        self.subject = "\(product.name) by \(product.brandName) on Primer"
        self.urlString = "https://primer.com/partners/\(product.brandSlug)/\(product.slug)"
        self.message = "What do you think of \(product.name) by \(product.brandName)? You can view it directly in your space as well as try other options with Primer's augmented reality app:\n\n\(urlString)"
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return message
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return message
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        
        // adds subject for mail sharing type
        if activityType == .mail {
            return subject
        }
        return ""
    }
}
