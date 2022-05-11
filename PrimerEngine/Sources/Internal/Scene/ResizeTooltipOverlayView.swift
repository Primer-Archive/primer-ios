//
//  ResizeTooltipOverlayView.swift
//  PrimerTwo
//
//  Created by Tony Morales on 3/9/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import ARKit

final class ResizeTooltipOverlayView: UIView {
    
    private let tooltipLabel = TooltipView(resizeTooltip: true,
                                           circleBackgroundOpacity: 0.4,
                                           innerCircleRadius: 46,
                                           outerCircleRadius: 64)
    
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(tooltipLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(swatch: Swatch, frame: ARFrame, interfaceOrientation: UIInterfaceOrientation) {
        
        func unproject(worldLocation: SIMD3<Float>) -> CGPoint {
            frame.camera.projectPoint(worldLocation, orientation: interfaceOrientation, viewportSize: bounds.size)
        }
        
        let rightGrabberAdjustedPosition = swatch.worldPosition(for: swatch.localResizeHandlesRectangle[.bottomRight], xOffset: -0.015, yOffset: 0.005)
        tooltipLabel.center = unproject(worldLocation: rightGrabberAdjustedPosition)
        let distanceFromCamera = CGFloat(simd_length(rightGrabberAdjustedPosition - frame.camera.transform.translation))
        if distanceFromCamera < 1 {
            tooltipLabel.highlight.transform = CATransform3DMakeScale(1 / distanceFromCamera, 1 / distanceFromCamera, 1)
        } else {
            tooltipLabel.highlight.transform = CATransform3DMakeScale(1, 1, 1)
        }
    }
}

public final class TooltipView: UIView {
    
    var highlight: HighlightLayer
    var resizeTooltip: Bool
    
    public init(resizeTooltip: Bool,
                circleBackgroundOpacity: CGFloat,
                innerCircleRadius: CGFloat,
                outerCircleRadius: CGFloat)
    {
        highlight = HighlightLayer(circleBackgroundOpacity: circleBackgroundOpacity,
                                   innerCircleRadius: innerCircleRadius,
                                   outerCircleRadius: outerCircleRadius)
        self.resizeTooltip = resizeTooltip
        super.init(frame: .zero)
        
        if resizeTooltip {
            let label = UILabel()
            let labelWidth: CGFloat = 220
            let labelHeight: CGFloat = 38
            let labelOffset: CGFloat = 70
            
            let labelText = NSMutableAttributedString(string: "")
            if let image = UIImage(systemName: "viewfinder.circle.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))
            {
                labelText.addImageAttachment(image: image, font: .systemFont(ofSize: 22), textColor: .white, size: CGSize(width: 22, height: 22))
            }
            labelText.append(NSAttributedString(string: "\u{200c}    Drag any corner to resize    \u{200c}"))

            label.attributedText = labelText
            label.textAlignment = .center
            label.font = .boldSystemFont(ofSize: 13)
            label.textColor = .white
            label.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
            label.layer.cornerRadius = labelHeight / 2
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOpacity = 0.24
            label.layer.shadowOffset = CGSize(width: 0, height: 6)
            label.layer.shadowRadius = 5
            label.layer.masksToBounds = true
            label.layer.zPosition = 1
            label.frame = CGRect(origin: CGPoint(x: -labelWidth / 2, y: labelOffset), size: CGSize(width: labelWidth, height: labelHeight))
            addSubview(label)
        }
        
        highlight.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        layer.addSublayer(highlight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.highlight.startAnimation()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSMutableAttributedString {
    func addImageAttachment(image: UIImage, font: UIFont, textColor: UIColor, size: CGSize? = nil) {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .strokeColor: textColor,
            .foregroundColor: textColor,
            .font: font
        ]

        self.append(
            NSAttributedString.init(
                //U+200C (zero-width non-joiner) is a non-printing character. It will not paste unnecessary space.
                string: "\u{200c}",
                attributes: textAttributes
            )
        )

        let attachment = NSTextAttachment()
        attachment.image = image.withRenderingMode(.alwaysTemplate)
        //Uncomment to set size of image.
        //FYI font.capHeight sets height of image equal to font size.
        let imageSize = size ?? CGSize.init(width: font.capHeight, height: font.capHeight)
        attachment.bounds = CGRect(
            x: 0,
            y: font.capHeight - imageSize.height,
            width: imageSize.width,
            height: imageSize.height
        )
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.addAttributes(
            textAttributes,
            range: NSMakeRange(
                0,
                attachmentString.length
            )
        )
        self.append(attachmentString)
    }
}

class HighlightLayer: CALayer {
    
    private var innerCircleEffect: CALayer?
    private var outerCircleEffect: CALayer?
    private var innerAnimationGroup: CAAnimationGroup?
    private var outerAnimationGroup: CAAnimationGroup?
    
    private var innerCircleRadius: CGFloat = 46.0
    private var outerCircleRadius: CGFloat = 64.0
    private var circleColor: UIColor = UIColor.white
    private var animationRepeatCount: Float = 10000.0
    private var innerCircleBorderWidth: CGFloat = 2
    private var outerCircleBorderWidth: CGFloat = 0
    private let animationDuration: CFTimeInterval = 2
    private var circleBackgroundOpacity: CGFloat = 0
    
    init(circleBackgroundOpacity: CGFloat, innerCircleRadius: CGFloat, outerCircleRadius: CGFloat) {
        self.circleBackgroundOpacity = circleBackgroundOpacity
        self.innerCircleRadius = innerCircleRadius
        self.outerCircleRadius = outerCircleRadius
        super.init()
        setupCircleEffects()
        
        repeatCount = animationRepeatCount
    }
    
    override init(layer: Any) {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        innerCircleEffect?.bounds = CGRect(x: 0, y: 0, width: innerCircleRadius * 2, height: innerCircleRadius * 2)
        innerCircleEffect?.cornerRadius = innerCircleRadius
        
        outerCircleEffect?.bounds = CGRect(x: 0, y: 0, width: outerCircleRadius * 2, height: outerCircleRadius * 2)
        outerCircleEffect?.cornerRadius = outerCircleRadius
    }
    
    private func setupCircleEffects() {
        innerCircleEffect = CALayer()
        innerCircleEffect?.borderWidth = innerCircleBorderWidth
        innerCircleEffect?.borderColor = circleColor.cgColor
        innerCircleEffect?.backgroundColor = circleColor.cgColor.copy(alpha: circleBackgroundOpacity)
        addSublayer(innerCircleEffect!)
        
        outerCircleEffect = CALayer()
        outerCircleEffect?.borderWidth = outerCircleBorderWidth
        outerCircleEffect?.borderColor = circleColor.cgColor
        addSublayer(outerCircleEffect!)
    }
    
    func startAnimation() {
        setupInnerAnimationGroup()
        innerCircleEffect?.add(innerAnimationGroup!, forKey: "innerHighlight")
        setupOuterAnimationGroup()
        outerCircleEffect?.add(outerAnimationGroup!, forKey: "outerHighlight")
    }
    
    func stopAnimation() {
        innerCircleEffect?.removeAnimation(forKey: "innerHighlight")
        outerCircleEffect?.removeAnimation(forKey: "outerHighlight")
    }
    
    private func setupInnerAnimationGroup() {
        
        let group = CAAnimationGroup()
        group.duration = animationDuration
        group.repeatCount = self.repeatCount
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let strokeAnimation = CAKeyframeAnimation(keyPath: "borderWidth")
        strokeAnimation.duration = animationDuration
        strokeAnimation.values = [2.0, 4.0, 2.0]
        strokeAnimation.keyTimes = [0, 0.5, 1]
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.duration = animationDuration
        scaleAnimation.values = [1.0, 1.08, 1.0]
        scaleAnimation.keyTimes = [0, 0.5, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = animationDuration
        opacityAnimation.values = [0.5, 1.0, 0.5]
        opacityAnimation.keyTimes = [0, 0.5, 1]
        
        group.animations = [strokeAnimation, scaleAnimation, opacityAnimation]
        
        innerAnimationGroup = group
        innerAnimationGroup!.delegate = self
    }
    
    private func setupOuterAnimationGroup() {
        
        let group = CAAnimationGroup()
        group.duration = animationDuration
        group.repeatCount = self.repeatCount
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let strokeAnimation = CAKeyframeAnimation(keyPath: "borderWidth")
        strokeAnimation.duration = animationDuration
        strokeAnimation.values = [0, 1, 0]
        strokeAnimation.keyTimes = [0.1, 0.5, 0.9]
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.duration = animationDuration
        scaleAnimation.values = [1.0, 1.143, 1.0]
        scaleAnimation.keyTimes = [0, 0.5, 1]
        
        group.animations = [strokeAnimation, scaleAnimation]
        
        outerAnimationGroup = group
        outerAnimationGroup!.delegate = self
    }
}

extension HighlightLayer: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let count = innerCircleEffect?.animationKeys()?.count , count > 0 {
            innerCircleEffect?.removeAllAnimations()
        }
        if let count = outerCircleEffect?.animationKeys()?.count , count > 0 {
            outerCircleEffect?.removeAllAnimations()
        }
    }
}
