//
//  WaterMarkView.swift
//  PrimerEngine
//
//  Created by James Hall on 12/14/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import UIKit
public class WaterMarkView: UIView {
    
    private let productNameLabel = UILabel()
    private let productBrandLabel = UILabel()
    private let labelStack = UIStackView()
    private let mainStack = UIView()
    private var logo = UIImageView()
    private var materialView = UIImageView()
    private let gradient = CAGradientLayer()
    private let containerView = UIView()
    
    var isDeviceIpad = (UIDevice.current.userInterfaceIdiom == .pad)
    
    public init(product: ProductModel, width: Int, height: Int) {
        super.init(frame: .zero)
        
        let backgroundColor = UIColor(red: 73 / 255, green: 77 / 255, blue: 90 / 255, alpha: 0.8)
        let containerHeight = 50 * UIScreen.main.scale
        
        // Main Stack
        //        mainStack.axis = .horizontal
        //        mainStack.distribution  = .fill
        //        mainStack.spacing = 30
        
        // Details Background
        containerView.backgroundColor = backgroundColor
        containerView.layer.cornerRadius = (containerHeight + 20) / 2
        containerView.layer.masksToBounds = true
        containerView.clipsToBounds = true
        
        // Name Label
        productNameLabel.text = product.name
        productNameLabel.textColor = .white
        productNameLabel.textAlignment = .left
        
        // Orb Swatch
        switch product.material.diffuse.content {
            case .color(let color):
                materialView.backgroundColor = color.uiColor
            case .constant:
                materialView.backgroundColor = .red
            case .inactive:
                materialView.backgroundColor = .green
            case .texture(let url):
                do {
                    let data = try Data(contentsOf: url)
                    let image = UIImage(data: data)
                    materialView.image = image
                } catch (let error) {
                    print("Failed to load texture: \(error.localizedDescription)")
                    materialView.backgroundColor = .red
                }
        }
        
        materialView.contentMode = .scaleAspectFill
        materialView.layer.cornerRadius = (containerHeight - 15) / 2
        materialView.layer.masksToBounds = true
        materialView.layer.borderWidth = 2 * UIScreen.main.scale
        materialView.layer.borderColor = UIColor.white.cgColor
        materialView.clipsToBounds = true
        containerView.addSubview(materialView)
        
        productNameLabel.font = UIFont.systemFont(ofSize: 16 * UIScreen.main.scale, weight: .medium)
        
        // Brand Label
        productBrandLabel.text = product.brandName
        productBrandLabel.textColor = .white
        productBrandLabel.textAlignment = .left
        productBrandLabel.font = UIFont.systemFont(ofSize: 14 * UIScreen.main.scale, weight: .medium)
        
        labelStack.axis = .vertical
        labelStack.distribution = .fillEqually
        labelStack.alignment = .leading
        labelStack.addArrangedSubview(productNameLabel)
        labelStack.addArrangedSubview(productBrandLabel)
        labelStack.frame = CGRect(x: containerHeight + 30, y: (35 / 2), width: isDeviceIpad ? (335 * UIScreen.main.scale) - (containerHeight + 30) : (235 * UIScreen.main.scale) - (containerHeight + 30), height: containerHeight - 15)
        containerView.addSubview(labelStack)
        
        mainStack.addSubview(containerView)
        
        // Logo
        let image = UIImage(named: "PrimerWatermark")
        logo.image = image
        logo.contentMode = .scaleToFill
        logo.frame = CGRect(x: mainStack.bounds.maxX - containerHeight, y: 0, width: containerHeight, height: containerHeight)
        logo.layer.cornerRadius = (containerHeight + 20) / 2
        logo.layer.masksToBounds = true
        logo.clipsToBounds = true
        logo.backgroundColor = backgroundColor
        
        mainStack.addSubview(logo)
        
        addSubview(mainStack)
        let totalWidth = CGFloat(width) * 0.87
        mainStack.frame = CGRect(x: 0, y: 0, width: totalWidth, height: containerHeight + 20)
        containerView.frame = CGRect(x: 0, y: 0, width: isDeviceIpad ? 335 * UIScreen.main.scale : 235 * UIScreen.main.scale, height: containerHeight + 20)
        materialView.frame = CGRect(x: 20, y: (35 / 2), width: containerHeight - 15, height: containerHeight - 15)
        
        logo.frame = CGRect(x: totalWidth - (containerHeight + 20), y: 0, width: containerHeight + 20, height: containerHeight + 20)
        
        gradient.colors = [UIColor.black.withAlphaComponent(0.2).cgColor, UIColor.clear.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.locations = [0.125, 0.25]
        layer.insertSublayer(gradient, at: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let containerHeight = (50 * UIScreen.main.scale) + 40
        mainStack.center = CGPoint(x: bounds.midX, y: isDeviceIpad ? bounds.maxY - containerHeight : bounds.maxY - (containerHeight * 1.45))
        
        gradient.frame = bounds
    }
}
