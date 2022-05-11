import Foundation
import UIKit
import ARKit

// The distance (in meters/world space) from the corners of the swatch that the lines
// should start and end.
private let cornerInset: Float = 0.05


final class MeasurementOverlayView: UIView {
    
    private let left = SegmentView()
    private let right = SegmentView()
    private let top = SegmentView()
    private let bottom = SegmentView()
    
    private let widthLabel = MeasurementView()
    private let heightLabel = MeasurementView()
    
    // In meters
    private let width: Double = 1.0
    private let height: Double = 1.0
    
    var topLeft: CGPoint = .zero {
        didSet { setNeedsLayout() }
    }
    
    var topRight: CGPoint = .zero {
        didSet { setNeedsLayout() }
    }
    
    var bottomLeft: CGPoint = .zero {
        didSet { setNeedsLayout() }
    }
    
    var bottomRight: CGPoint = .zero {
        didSet { setNeedsLayout() }
    }
    
    init() {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = false
        
        addSubview(left)
        addSubview(right)
        addSubview(top)
        addSubview(bottom)
        
        addSubview(widthLabel)
        addSubview(heightLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        left.frame = bounds
        right.frame = bounds
        top.frame = bounds
        bottom.frame = bounds
    }
    
    func update(swatch: Swatch, frame: ARFrame, interfaceOrientation: UIInterfaceOrientation) {
        func unproject(worldLocation: SIMD3<Float>) -> CGPoint {
            frame.camera.projectPoint(worldLocation, orientation: interfaceOrientation, viewportSize: bounds.size)
        }
        
        var topStart = swatch.localResizeHandlesRectangle[.topLeft]
        var topEnd = swatch.localResizeHandlesRectangle[.topRight]
        topStart.x += cornerInset
        topEnd.x -= cornerInset
        top.from = unproject(worldLocation: swatch.worldPosition(for: topStart))
        top.to = unproject(worldLocation: swatch.worldPosition(for: topEnd))
        
        var bottomStart = swatch.localResizeHandlesRectangle[.bottomLeft]
        var bottomEnd = swatch.localResizeHandlesRectangle[.bottomRight]
        bottomStart.x += cornerInset
        bottomEnd.x -= cornerInset
        bottom.from = unproject(worldLocation: swatch.worldPosition(for: bottomStart))
        bottom.to = unproject(worldLocation: swatch.worldPosition(for: bottomEnd))
        
        var leftStart = swatch.localResizeHandlesRectangle[.topLeft]
        var leftEnd = swatch.localResizeHandlesRectangle[.bottomLeft]
        leftStart.y -= cornerInset
        leftEnd.y += cornerInset
        left.from = unproject(worldLocation: swatch.worldPosition(for: leftStart))
        left.to = unproject(worldLocation: swatch.worldPosition(for: leftEnd))
        
        var rightStart = swatch.localResizeHandlesRectangle[.topRight]
        var rightEnd = swatch.localResizeHandlesRectangle[.bottomRight]
        rightStart.y -= cornerInset
        rightEnd.y += cornerInset
        right.from = unproject(worldLocation: swatch.worldPosition(for: rightStart))
        right.to = unproject(worldLocation: swatch.worldPosition(for: rightEnd))
        
        widthLabel.length = swatch.size.width
        widthLabel.sizeToFit()
        widthLabel.center = unproject(worldLocation: swatch.worldPosition(for: swatch.localResizeHandlesRectangle[.right]))
        
        heightLabel.length = swatch.size.height
        heightLabel.sizeToFit()
        heightLabel.center = unproject(worldLocation: swatch.worldPosition(for: swatch.localResizeHandlesRectangle[.bottom]))

        
        
        
    }
    
}





fileprivate final class SegmentView: UIView {
    
    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }
    
    private var shapeLayer: CAShapeLayer {
        layer as! CAShapeLayer
    }
    
    var from: CGPoint = .zero {
        didSet {
            updateShapeLayer()
        }
    }
    
    var to: CGPoint = .zero {
        didSet {
            updateShapeLayer()
        }
    }
    
    private static let lineThickness: CGFloat = 8.0
    private static let lineColor: UIColor = UIColor.black.withAlphaComponent(0.2)

    init() {
        
        super.init(frame: .zero)

        shapeLayer.strokeColor = Self.lineColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = Self.lineThickness

        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOpacity = 0.24
        shapeLayer.shadowOffset = CGSize(width: 0, height: 6)
        shapeLayer.shadowRadius = 5

        self.isOpaque = false
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateShapeLayer() {
        let path = UIBezierPath()
        let start = from
        let end = to
        path.move(to: start)
        path.addLine(to: end)
        shapeLayer.path = path.cgPath
    }

}


fileprivate final class MeasurementView: UIView {
    
    private let label = UILabel()
    private let formatter = LengthFormatter()
    
    var length: Float = 0.0 {
        didSet {
            updateText()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = .systemBackground
        
        layer.cornerRadius = 6.0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.24
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 5
        
        label.text = "7'4\""
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        addSubview(label)
        
        formatter.unitStyle = .short
        formatter.isForPersonHeightUse = true
        formatter.numberFormatter.maximumFractionDigits = 0

        updateText()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = label.sizeThatFits(size)
        return CGSize(
            width: labelSize.width + 16.0,
            height: labelSize.height + 8.0)
    }
    
    private func updateText() {
        DispatchQueue.main.async {
            self.label.text = self.formatter.string(fromMeters: Double(self.length))
        }
        
    }
    
}
