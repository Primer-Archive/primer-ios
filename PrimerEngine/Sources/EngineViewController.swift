import MetalKit
import MetalPerformanceShaders
import ARKit
import SwiftUI
import Sentry

private let swatchDefaultSize: Float = 0.4
private let swatchMinimumSize: Float = 0.2

// The radius of a circle in world space
private let resizeHandleTouchRadius: Float = 0.08

private let lowLightWarningLumens: CGFloat = 100
private let lowLightTimeDelay: TimeInterval = 2

final class EngineViewController: UIViewController {
    
    var stateBinding: Binding<EngineState> = .constant(EngineState()) {
        didSet {
            stateDidChange()
        }
    }
    
    var onEvent: (EngineEvent,Swatch) -> Void = { _,_ in }
    
    private var state: EngineState {
        get { stateBinding.wrappedValue }
        set {
            stateBinding.wrappedValue = newValue
            stateDidChange()
        }
    }
    
    var material: CachedMaterial? {
        get { sceneController.material }
        set {
            if material?.material.id != newValue?.material.id {
                sceneController.material = newValue
                updateSwatchMaximumSize()
            }
        }
    }

    var swatchMaximumSize: Swatch.Size = Swatch.Size(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude) {
        didSet {
            didUpdateSwatchMaximumSize()
        }
    }
    
    private let sceneController: SceneController
    private let sceneView: CustomSceneView
    
    private let videoRecorder = MetalVideoRecorder()
    private let smartPlacementManager = SmartPlacementManager()
    
    private let panRecognizer = UIPanGestureRecognizer()
    private let pinchRecognizer = UIPinchGestureRecognizer()
    private let doubleTapRecognizer = UITapGestureRecognizer()
    
    private let resizeTooltipOverlay = ResizeTooltipOverlayView()
    
    private let coachingOverlayView = ARCoachingOverlayView()
    
    private let impactGenerator = UISelectionFeedbackGenerator()
    
    private let spinner = UIActivityIndicatorView(style: .large)
    private let spinnerBG = UIView()

    private let debugSwatchBlending = false
    private let swatchBlendingDisabled = UILabel()
    private let swatchBlendingDisabledSlider = UISlider()
    private let swatchBlendingIntensity = UILabel()
    private let swatchBlendingIntensitySlider = UISlider()
    private let swatchBlendingLighten = UILabel()
    private let swatchBlendingLightenSlider = UISlider()

    private var sceneLightsDebugPanel: SceneLightsDebugPanel? = nil
    private let debugLightIntensity = true

    private var firstLightEstimateTime: TimeInterval? = nil
    private var ambientIntensity: CGFloat = 1000.0 {
        didSet {
            guard let firstTime = firstLightEstimateTime else {
                firstLightEstimateTime = Date().timeIntervalSince1970
                return
            }
            if (Date().timeIntervalSince1970 - firstTime) <= lowLightTimeDelay {
                return
            }
            if ambientIntensity >= lowLightWarningLumens && oldValue < lowLightWarningLumens {
                state.lowLightWarning = false
            } else if ambientIntensity < lowLightWarningLumens && oldValue >= lowLightWarningLumens {
                state.lowLightWarning = true
            }
        }
    }
    public var ambientTemperature: CGFloat = 6500.0
    
    // When we reset a session, sometimes delegate methods are still called with old data, so
    // we store the session ids of the finished sessions here so we can ignore correlated callbacks
    private var finishedSessionIds: [UUID: Bool] = [:]

    private var resetTime: TimeInterval = 0 {
        didSet {
            guard resetTime != oldValue else { return }
            firstLightEstimateTime = nil
            resetARSession()
        }
    }

    private var isRunning: Bool = false {
        didSet {
            guard isRunning != oldValue else { return }
            if isRunning {
                startARSession()
            } else {
                pauseARSession()
            }
        }
    }
    var _size:CGSize!
    var currentSize:CGSize {
        if _size == nil {
            _size = sceneView.bounds.size
        }
        return _size
    }
    var _orientation:UIInterfaceOrientation!
    var currentInterfaceOrientation: UIInterfaceOrientation {
        if _orientation == nil {
            _orientation = view.window?.windowScene?.interfaceOrientation ?? .portrait
        }
        
        return _orientation
    }

    
    init() {
        sceneView = CustomSceneView()
        sceneController = SceneController(sceneView: sceneView)
        super.init(nibName: nil, bundle: nil)
        sceneView.delegate = self
        sceneView.session.delegate = self

        smartPlacementManager.onStateChange = { (nextState: EngineState.SmartPlacementState) in
            var tmp = self.state
            tmp.smartPlacementState = nextState
            self.state = tmp
        }

        do {
            Client.shared = try Client(dsn: ENV.sentryDSN)
        } catch let error {
            print("Could not initialize Sentry client \(error)")
        }

        DispatchQueue.main.async {
            if self.debugSwatchBlending {
                self.setupSwatchBlendingDebug()
            }
            self.setupLoadingSpinner()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(sceneView)

        sceneLightsDebugPanel = SceneLightsDebugPanel(sceneLights: sceneController.sceneLights, view: view)

        view.isMultipleTouchEnabled = false

        panRecognizer.addTarget(self, action: #selector(pan))
        panRecognizer.delegate = self
        view.addGestureRecognizer(panRecognizer)

        pinchRecognizer.addTarget(self, action: #selector(pinch))
        view.addGestureRecognizer(pinchRecognizer)

        doubleTapRecognizer.addTarget(self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapRecognizer)

        if !state.hideResizeTooltip {
            resizeTooltipOverlay.alpha = 1.0
            
        }
        view.addSubview(resizeTooltipOverlay)

        setupCoachingOverlay()

        if UIDevice.current.userInterfaceIdiom == .pad {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        isRunning = true
        
        sceneView.frame = view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isRunning = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeTooltipOverlay.frame = view.bounds
        coachingOverlayView.frame = view.bounds
    }
    
    private func arSessionConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .manual
        
        if #available(iOS 13.4, *) {
            configuration.planeDetection = [.vertical, .horizontal]
            if type(of: configuration).supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = [.mesh]
            }
        }
        
        if type(of: configuration).supportsFrameSemantics(.personSegmentation) {
            configuration.frameSemantics.insert(.personSegmentation)
        }
        
        return configuration
    }

    private func startARSession() {
        #if !targetEnvironment(simulator)
        sceneView.session.run(arSessionConfiguration())
        #endif
    }
    
    private func pauseARSession() {
        sceneView.session.pause()
    }
    
    private func resetARSession() {
        finishedSessionIds[sceneView.session.identifier] = true
        sceneController.reset()
        #if !targetEnvironment(simulator)
        sceneView.session.run(arSessionConfiguration(), options: [.resetTracking, .removeExistingAnchors,
                                                                  .stopTrackedRaycasts, .resetSceneReconstruction])
        #endif
        sceneLightsDebugPanel?.resetValues()
        state.lidarDidFindWall = true // reset to default
    }

    private func stateDidChange() {
        if(self.isRunning != state.isRunning){
            self.isRunning = state.isRunning
        }
        resetTime = state.resetTime
        sceneController.swatch = state.swatch
        sceneController.placementSwatch = state.placementSwatch
        sceneController.activeGestureType = state.activeGestureType
        smartPlacementManager.state = state.smartPlacementState
        if debugSwatchBlending {
            DispatchQueue.main.async {
                self.swatchBlendingLighten.superview?.isHidden = !self.sceneController.swatchNode.blendActive
            }
        }
        updateResizeTooltipOverlay()
    }
    
    public func getSnapshot() -> UIImage {
        return sceneView.snapshot()
    }
    private func updateResizeTooltipOverlay() {
        DispatchQueue.main.async { [self] in
            if self.state.hideResizeTooltip {
                self.resizeTooltipOverlay.isHidden = true
                return
            }
            
            if let swatch = self.state.swatch,
               let frame = self.sceneView.session.currentFrame
            {
                self.resizeTooltipOverlay.isHidden = false
                self.resizeTooltipOverlay.update(
                    swatch: swatch,
                    frame: frame,
                    interfaceOrientation: self.currentInterfaceOrientation)
            } else {
                self.resizeTooltipOverlay.alpha = 1.0
                self.resizeTooltipOverlay.isHidden = true
            }
        }
    }
    
    @objc private func pan(_ recognizer: UIPanGestureRecognizer) {
        guard let frame = sceneView.session.currentFrame else { return }
        
        switch recognizer.state {
            case .began:
                guard let swatch = state.swatch else {
                    return
                }
                let location = recognizer.location(in: view)
                guard let positionOnPlane = positionOnPlane(from: location) else { return }
                
                // Finds the closes resize handle to the touch point that is within a 24pt in screen space.
                // This is the fallback mechanism to handle the case where the device is very far from
                // the wall plane, so the world-space hit area is unusable. This always provides a screen-space
                // fallback area.
                let validResizeHandleInScreenSpace = Swatch.Corner.allCases
                    .map { corner -> (corner: Swatch.Corner, distance: CGFloat) in
                        let localPosition = swatch.localResizeHandlesRectangle[corner: corner]
                        let worldPosition = swatch.worldPosition(for: localPosition)
                        let screenPoint = frame.camera.projectPoint(worldPosition, orientation: self.currentInterfaceOrientation, viewportSize: self.view.bounds.size)
                        let deltaX = screenPoint.x - location.x
                        let deltaY = screenPoint.y - location.y
                        let lengthSquared = deltaX*deltaX + deltaY*deltaY
                        return (corner: corner, distance: sqrt(lengthSquared))
                    }
                    .filter { $0.distance < 24.0 }
                    .sorted { $0.distance < $1.distance }
                    .map { $0.corner }
                    .first
                
                if let corner = (swatch.validResizeHandleCorner(for: positionOnPlane) ?? validResizeHandleInScreenSpace) {
                    state.gestureState = .resize(
                        initialSwatch: swatch,
                        initialPointOnPlane: positionOnPlane,
                        latestLocationInView: location,
                        corner: corner)
                    state.hideResizeTooltip = true
                } else {
                    state.gestureState = .move(
                        initialSwatch: swatch,
                        initialPointOnPlane: positionOnPlane,
                        latestLocationInView: location)
                }
                
                
                if case .resize = state.gestureState {
                    UIView.animate(withDuration: 0.2) {
                        self.resizeTooltipOverlay.alpha = 0.0
                    }
                }
                
                
                
            case .changed:
                switch state.gestureState {
                    case .inactive:
                        return
                    case .move(let initialSwatch, let initialPointOnPlane, _):
                        state.gestureState = .move(
                            initialSwatch: initialSwatch,
                            initialPointOnPlane: initialPointOnPlane,
                            latestLocationInView: recognizer.location(in: view))
                    case .resize(let initialSwatch, let initialPointOnPlane, _, let corner):
                        state.gestureState = .resize(
                            initialSwatch: initialSwatch,
                            initialPointOnPlane: initialPointOnPlane,
                            latestLocationInView: recognizer.location(in: view),
                            corner: corner)
                    case .pinch:
                        // Drag recognizer doesn't update pinch.
                        break
                }
                updateInProgressGesture()
            case .ended, .cancelled:
                switch state.gestureState {
                    case .inactive: break
                    case .move:
                        onEvent(.movedSwatch, state.swatch!)
                    case .resize:
                        onEvent(.resizedSwatch, state.swatch!)
                    case .pinch:
                        break // not used by pan recognizer
                }
                state.gestureState = .inactive
            default:
                break
        }
    }
    
    @objc private func pinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
            case .began:
                guard let swatch = state.swatch else {
                    return
                }
                state.gestureState = .pinch(
                    initialSwatch: swatch,
                    latestScale: recognizer.scale)
            case .changed:
                guard case .pinch(let initialSwatch, _) = state.gestureState else {
                    return
                }
                state.gestureState = .pinch(
                    initialSwatch: initialSwatch,
                    latestScale: recognizer.scale)
                updateInProgressGesture()
            case .ended, .cancelled:
                state.gestureState = .inactive
                onEvent(.resizedSwatch, state.swatch!)
            default:
                break
        }
    }

    @objc private func doubleTap(_ recognizer: UITapGestureRecognizer) {
        return
        if let debug = sceneLightsDebugPanel {
            debug.isHidden = !debug.isHidden
        }
    }
    
    private func updateInProgressGesture() {
        switch state.gestureState {
            case .inactive:
                break
            case .move(let initialSwatch, let initialPointOnPlane, let latestLocationInView):
                guard let currentPoint = positionOnPlane(from: latestLocationInView) else {
                    return
                }
                let translation = SIMD2(currentPoint.x - initialPointOnPlane.x, currentPoint.y - initialPointOnPlane.y)
                var swatch = initialSwatch
                swatch.translation.x += translation.x
                swatch.translation.y += translation.y
                state.swatch = swatch
            case .resize(let initialSwatch, let initialPointOnPlane, let latestLocationInView, let corner):
                guard let currentPoint = positionOnPlane(from: latestLocationInView) else {
                    return
                }
                var translation = SIMD2(currentPoint.x - initialPointOnPlane.x, currentPoint.y - initialPointOnPlane.y)
                var swatch = initialSwatch
                switch corner {
                    case .topLeft:
                        translation.x = max(min(translation.x, Float(swatch.size.width - swatchMinimumSize)), swatch.size.width - swatchMaximumSize.width)
                        translation.y = min(max(translation.y, Float(swatchMinimumSize - swatch.size.height)), swatchMaximumSize.height - swatch.size.height)
                        swatch.translation.x += translation.x * 0.5
                        swatch.translation.y += translation.y * 0.5
                        swatch.size.width -= translation.x
                        swatch.size.height += translation.y
                    case .topRight:
                        translation.x = min(max(translation.x, Float(swatchMinimumSize - swatch.size.width)), swatchMaximumSize.width - swatch.size.width)
                        translation.y = min(max(translation.y, Float(swatchMinimumSize - swatch.size.height)), swatchMaximumSize.height - swatch.size.height)
                        swatch.translation.x += translation.x * 0.5
                        swatch.translation.y += translation.y * 0.5
                        swatch.size.width += translation.x
                        swatch.size.height += translation.y
                    case .bottomLeft:
                        translation.x = max(min(translation.x, Float(swatch.size.width - swatchMinimumSize)), swatch.size.width - swatchMaximumSize.width)
                        translation.y = max(min(translation.y, Float(swatch.size.height - swatchMinimumSize)), swatch.size.height - swatchMaximumSize.height)
                        swatch.translation.x += translation.x * 0.5
                        swatch.translation.y += translation.y * 0.5
                        swatch.size.width -= translation.x
                        swatch.size.height -= translation.y
                    case .bottomRight:
                        translation.x = min(max(translation.x, Float(swatchMinimumSize - swatch.size.width)), swatchMaximumSize.width - swatch.size.width)
                        translation.y = max(min(translation.y, Float(swatch.size.height - swatchMinimumSize)), swatch.size.height - swatchMaximumSize.height)
                        swatch.translation.x += translation.x * 0.5
                        swatch.translation.y += translation.y * 0.5
                        swatch.size.width += translation.x
                        swatch.size.height -= translation.y
                }
                state.swatch = swatch
            case .pinch(let initialSwatch, let latestScale):
                var swatch = initialSwatch
                swatch.size.width *= Float(latestScale)
                swatch.size.height *= Float(latestScale)
                swatch.size.width = min(max(swatch.size.width, swatchMinimumSize), swatchMaximumSize.width)
                swatch.size.height = min(max(swatch.size.height, swatchMinimumSize), swatchMaximumSize.height)
                state.swatch = swatch
        }
        
    }
    
    private func unproject(point: CGPoint) -> SIMD3<Float>? {
        guard let frame = sceneView.session.currentFrame else { return nil }
        guard let swatch = state.swatch else { return nil }
        
        return frame.camera.unprojectPoint(point, ontoPlane: swatch.planeTransform, orientation: currentInterfaceOrientation, viewportSize: currentSize)
    }
    
    private func positionOnPlane(from screenPoint: CGPoint) -> Swatch.Position? {
        guard let swatch = state.swatch else { return nil }
        
        // Get the point in space (in global coordinates) that intersects the swatch plane
        guard let worldPosition = unproject(point: screenPoint) else { return nil }
        
        // Convert to swatch local swatch coordinates
        return swatch.intersectingLocalPositionOnPlane(for: worldPosition)
    }

    private func updateSwatchMaximumSize() {
        var size = Swatch.Size(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        if let maxSize = sceneController.material?.material.maxSize {
            if maxSize.width > 0 {
                size.width = Float(maxSize.width)
            }
            if maxSize.height > 0 {
                size.height = Float(maxSize.height)
            }
        }
        swatchMaximumSize = size
    }

    private func didUpdateSwatchMaximumSize() {
        guard var size = state.swatch?.size else {
            return
        }
        var changed = false
        if size.width > swatchMaximumSize.width {
            size.width = swatchMaximumSize.width
            changed = true
        }
        if size.height > swatchMaximumSize.height {
            size.height = swatchMaximumSize.height
            changed = true
        }
        if changed {
            DispatchQueue.main.async {
                guard var swatch = self.state.swatch else {
                    return
                }
                swatch.size = size
                self.state.swatch = swatch
            }
        }
    }

    private func setupLoadingSpinner() {
        spinnerBG.isHidden = true
        spinnerBG.center = view.center
        spinnerBG.backgroundColor = UIColor(white: 0, alpha: 0.45)
        spinnerBG.layer.cornerRadius = 10
        view.addSubview(spinnerBG)

        spinner.isHidden = true
        spinner.center = view.center
        view.addSubview(spinner)
    }

    private func updateLoadingSpinner() {
        if sceneController.shouldShowLoadingSpinner && !spinner.isAnimating {
            spinner.isHidden = false
            spinner.startAnimating()
        } else if !sceneController.shouldShowLoadingSpinner && spinner.isAnimating {
            spinner.isHidden = true
            spinner.stopAnimating()
        }

        if !spinner.isHidden {
            let hasSwatch = state.swatch != nil
            let hasMaterial = material != nil
            let isNarrow = (state.swatch?.size.width ?? 0) <= 1.8288 // 6 feet
            let isShort = (state.swatch?.size.height ?? 0) <= 1.8288
            if hasSwatch && hasMaterial && isNarrow && isShort,
               let point = sceneView.session.currentFrame?.camera.projectPoint(sceneController.swatchPos, orientation: .portrait, viewportSize: view.bounds.size),
               view.bounds.contains(point) {
                spinner.center = point
                spinner.style = .medium
                spinnerBG.frame.size = CGSize(width: 40, height: 40)
            } else {
                spinner.center = view.center
                spinner.style = .large
                spinnerBG.frame.size = CGSize(width: 80, height: 80)
            }
            spinnerBG.center = spinner.center
        }
        if spinnerBG.isHidden != spinner.isHidden {
            spinnerBG.isHidden = spinner.isHidden
        }
    }

    private func setupSwatchBlendingDebug() {
        swatchBlendingDisabledSlider.minimumValue = 0
        swatchBlendingDisabledSlider.maximumValue = 1
        swatchBlendingDisabledSlider.value = sceneController.swatchNode.blendDisabled ? 0.0 : 1.0
        swatchBlendingDisabledSlider.isContinuous = true
        swatchBlendingDisabledSlider.addTarget(self, action: #selector(swatchBlendingDisabledChanged), for: .valueChanged)

        swatchBlendingIntensitySlider.minimumValue = 0
        swatchBlendingIntensitySlider.maximumValue = 1
        swatchBlendingIntensitySlider.value = sceneController.swatchNode.blendIntensity
        swatchBlendingIntensitySlider.isContinuous = true
        swatchBlendingIntensitySlider.addTarget(self, action: #selector(swatchBlendingIntensityChanged), for: .valueChanged)

        swatchBlendingLightenSlider.minimumValue = 0
        swatchBlendingLightenSlider.maximumValue = 1
        swatchBlendingLightenSlider.value = sceneController.swatchNode.blendLighten
        swatchBlendingLightenSlider.isContinuous = true
        swatchBlendingLightenSlider.addTarget(self, action: #selector(swatchBlendingLightenChanged), for: .valueChanged)

        updateSwatchBlendingLabel()

        let stackView = UIStackView(arrangedSubviews: [swatchBlendingDisabled, swatchBlendingDisabledSlider,
                                                       swatchBlendingIntensity, swatchBlendingIntensitySlider,
                                                       swatchBlendingLighten, swatchBlendingLightenSlider])
        stackView.isHidden = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = -2
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -255),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    @objc
    private func swatchBlendingDisabledChanged(view: UIView) {
        sceneController.swatchNode.blendDisabled = Int(swatchBlendingDisabledSlider.value.rounded()) < 1
        updateSwatchBlendingLabel()
    }

    @objc
    private func swatchBlendingIntensityChanged(view: UIView) {
        sceneController.swatchNode.blendIntensity = swatchBlendingIntensitySlider.value
        updateSwatchBlendingLabel()
    }

    @objc
    private func swatchBlendingLightenChanged(view: UIView) {
        sceneController.swatchNode.blendLighten = swatchBlendingLightenSlider.value
        updateSwatchBlendingLabel()
    }

    private func updateSwatchBlendingLabel() {
        swatchBlendingDisabled.text = "Blending " + (sceneController.swatchNode.blendDisabled ? "Disabled" : "Enabled")
        let intensityFmt = String(format: "%.2f", sceneController.swatchNode.blendIntensity)
        swatchBlendingIntensity.text = "Blend Intensity: \(intensityFmt)"
        let lightenFmt = String(format: "%.2f", sceneController.swatchNode.blendLighten)
        swatchBlendingLighten.text = "Blend Lighten: \(lightenFmt)"
    }
}

@objc extension EngineViewController {
    func orientationChanged(_ notification: NSNotification) {
        let device = notification.object as! UIDevice
        let deviceOrientation = device.orientation
        
        sceneView.frame = view.bounds
        

        
        
        switch deviceOrientation {
            case .landscapeLeft:   //do something for landscape left
                _orientation = .landscapeRight //these have to be flipped for some reason :\
            case .landscapeRight:  //do something for landscape right
                _orientation = .landscapeLeft
            case .portrait:        //do something for portrait
                _orientation = .portrait
            case .portraitUpsideDown: //do something for portrait upside-down
                _orientation = .portraitUpsideDown
            case .faceDown:        //do something for face down
                _orientation = .portrait
            case .faceUp:          //do something for face up
                _orientation = .portrait
            case .unknown:         //handle unknown
                let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            
                _orientation = scene.interfaceOrientation
            @unknown default:      //handle unknown default
                _orientation = .portrait
        }
        
        _size = sceneView.bounds.size

    }
}

// Video Recording
extension EngineViewController {
    
    var isRecordingVideo: Bool {
        videoRecorder.isActive
    }
    
    var isFinishingRecordingVideo: Bool {
        videoRecorder.isFinishing
    }
    
    func startRecordingVideo(selectedProduct: ProductModel?, variationIndex: Int) {
        DispatchQueue.main.async {
            self.videoRecorder.startRecording(width: Int(self.sceneView.frameSize.width), height: Int(self.sceneView.frameSize.height), selectedProduct: selectedProduct, encodeOnGPU: UIDevice.isGPUPowered())
        }
    }
    
    func stopRecordingVideo(completion: @escaping (URL?) -> Void) {
        videoRecorder.endRecording(completion)
    }
    
    func placeSwatch(planeInformation: (heading: Float, position: SIMD3<Float>)? = nil, forPlacement: Bool = false) {
        guard var placement = swatchPlacementValuesForCurrentDevicePosition else {
            return
        }

        if planeInformation != nil {
            placement = planeInformation!
        }

        state.lidarDidFindWall = true
        
        if(!forPlacement){
            guard state.swatch == nil else {
                return
            }
        }
        
        let swatch = Swatch(
            position: placement.position,
            angle: placement.heading,
            size: Swatch.Size(
                width: swatchDefaultSize,
                height: swatchDefaultSize))

        if(forPlacement){
            state.placementSwatch = swatch
        }else{
            state.swatch = swatch
            impactGenerator.selectionChanged()
            
            onEvent(.placedSwatch, state.swatch!)
        }
    }
    
    private var swatchPlacementValuesForCurrentDevicePosition: (heading: Float, position: SIMD3<Float>)? {
        
        guard let pov = sceneView.pointOfView else { return nil }
        
        let localYDelta: Float = 0.01
        
        func markerPositions(for cameraTransform: SCNMatrix4) -> (left: SCNVector3, right: SCNVector3) {
            // How far to project left and right to form a line from the top of the device
            let horizontalProjectionDistance: Float = 0.02
            return (
                left: cameraTransform * SCNVector3(-horizontalProjectionDistance, localYDelta, 0),
                right: cameraTransform * SCNVector3(horizontalProjectionDistance, localYDelta, 0)
            )
        }
        
        let heading: Float = {
            let (left, right) = markerPositions(for: pov.worldTransform)
            let pointA = SIMD3<Float>(left)
            let pointB = SIMD3<Float>(right)
            let angle = atan2f(pointA.x - pointB.x, pointA.z - pointB.z) + (Float.pi/2.0)
            return angle
        }()
        
        let position = pov.convertPosition(SCNVector3(0, localYDelta, 0), to: sceneView.scene.rootNode)
        return (heading: heading, position: SIMD3(position))
    }
    
    private var swatchPlacementValuesForLidarDevicePosition: (heading: Float, position: SIMD3<Float>)? {
        
        guard let pov = sceneView.pointOfView else { return nil }
        
        let localYDelta: Float = 0.03
        let localZDelta: Float = -0.5
        
        func markerPositions(for cameraTransform: SCNMatrix4) -> (left: SCNVector3, right: SCNVector3) {
            // How far to project left and right to form a line from the top of the device
            let horizontalProjectionDistance: Float = 0.02
            return (
                left: cameraTransform * SCNVector3(-horizontalProjectionDistance, localYDelta, 0),
                right: cameraTransform * SCNVector3(horizontalProjectionDistance, localYDelta, 0)
            )
        }
        
        let heading: Float = {
            let (left, right) = markerPositions(for: pov.worldTransform)
            let pointA = SIMD3<Float>(left)
            let pointB = SIMD3<Float>(right)
            let angle = atan2f(pointA.x - pointB.x, pointA.z - pointB.z) + (Float.pi/2.0)
            return angle
        }()
        
        let position = pov.convertPosition(SCNVector3(0, 0, localZDelta), to: sceneView.scene.rootNode)
        return (heading: heading, position: SIMD3(position))
    }
    
}

// MARK: - ARCoachingOverlayViewDelegate

extension EngineViewController: ARCoachingOverlayViewDelegate {
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func setupCoachingOverlay() {
        coachingOverlayView.session = sceneView.session
        coachingOverlayView.delegate = self
        coachingOverlayView.goal = .tracking
        view.addSubview(coachingOverlayView)
    }
}

extension EngineViewController: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        ambientIntensity = frame.lightEstimate?.ambientIntensity ?? 1000.0
        ambientTemperature = frame.lightEstimate?.ambientColorTemperature ?? 6500.0

        smartPlacementManager.didUpdate(session: session, frame: frame)

        DispatchQueue.main.async {
            self.state.worldMappingStatus = frame.worldMappingStatus
            self.state.trackingState = frame.camera.trackingState
            self.updateLoadingSpinner()
        }
    }
}

extension EngineViewController: ARSCNViewDelegate, SCNSceneRendererDelegate {
    
    // MARK: Adding Custom Logic to the Rendering Loop
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if finishedSessionIds[sceneView.session.identifier] != nil {
            return
        }

        var temperature = ambientTemperature
        if let debug = sceneLightsDebugPanel {
            temperature += debug.ambientTemperatureOffset
        }
        sceneController.update(for: renderer, intensity: ambientIntensity, temperature: temperature)

        if let frame = sceneView.session.currentFrame {
            DispatchQueue.main.async {
                self.sceneLightsDebugPanel?.update(frame: frame)
            }
        }
    }
    
    // MARK: Rendering Custom Scene Content
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if self.videoRecorder.isReadyForTexture, let texture = self.sceneView.frameContents {
            self.videoRecorder.writeFrame(forTexture: texture)
        }
    }
    
}

extension EngineViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panRecognizer {
            guard state.gestureState == .inactive else { return false }
            guard let swatch = state.swatch else { return false }
            let location = gestureRecognizer.location(in: view)
            guard let positionOnPlane = positionOnPlane(from: location) else {
                return false
            }
            if swatch.validResizeHandleCorner(for: positionOnPlane) != nil {
                return true
            }
            return true
        }
        return true
    }
    
}


extension EngineViewController {
    fileprivate static let resizeHandleTouchAreaSize: CGFloat = 64.0
}

extension CGPoint {
    fileprivate func boundingBox(size: CGFloat) -> CGRect {
        return CGRect(
            x: x - size/2.0,
            y: y - size/2.0,
            width: size,
            height: size)
    }
}

fileprivate extension Swatch {
    
    func validResizeHandleCorner(for positionOnPlane: Position) -> Corner? {
        for corner in Swatch.Corner.allCases {
            let boundingCircle = localResizeHandlesRectangle[corner: corner]
                .boundingCircle(radius: resizeHandleTouchRadius)
            if boundingCircle.contains(position: positionOnPlane) {
                return corner
            }
        }
        return nil
    }
    
}

extension SIMD4 where Scalar == Float {
    fileprivate init(_ vector: SCNVector4) {
        self.init(vector.x, vector.y, vector.z, vector.w)
    }
    
    fileprivate init(_ vector: SCNVector3) {
        self.init(vector.x, vector.y, vector.z, 1)
    }
}

extension SCNVector3 {
    fileprivate init(_ vector: SIMD4<Float>) {
        self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
    }
}

fileprivate func * (left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
    let matrix = float4x4(left)
    let vector = SIMD4<Float>(right)
    let result = matrix * vector
    return SCNVector3(result)
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}


extension EngineViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 13.4, *), ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            if state.swatch == nil{
                rayCastThrow(touches, forPlacement: true)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 13.4, *), ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            if(state.swatch == nil){
                rayCastThrow(touches, forPlacement: true)
            }else{
                rayCastThrow(touches, forPlacement: false)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if #available(iOS 13.4, *), ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            rayCastThrow(touches, forPlacement: false)
        }else{
            placeSwatch()
        }
    }
    
    func rayCastThrow(_ touches: Set<UITouch>, forPlacement: Bool){
        let touch = touches.first!
        let tapLocation = touch.location(in: sceneView)
        guard let raycastQuery = sceneView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .any) else { return }
        
        if let result = sceneView.session.raycast(raycastQuery).first {
            
            guard let frame = sceneView.session.currentFrame else {
                return
            }
            
            let hitTestTransform = SCNMatrix4(result.worldTransform)
            
            let localYDelta: Float = 0.01
            
            func markerPositions(for cameraTransform: SCNMatrix4) -> (left: SCNVector3, right: SCNVector3) {
                // How far to project left and right to form a line from the top of the device
                let horizontalProjectionDistance: Float = 0.02
                return (
                    left: cameraTransform * SCNVector3(-horizontalProjectionDistance, localYDelta, 0),
                    right: cameraTransform * SCNVector3(horizontalProjectionDistance, localYDelta, 0)
                )
            }
            
            let heading: Float = {
                let (left, right) = markerPositions(for: hitTestTransform)
                let pointA = SIMD3<Float>(left)
                let pointB = SIMD3<Float>(right)
                let angle = atan2f(pointA.x - pointB.x, pointA.z - pointB.z) + (Float.pi/2.0)
                return angle
            }()
            
            
            
            let rayDirection = normalize(result.worldTransform.position - frame.camera.transform.translation)
            let position = result.worldTransform.position - (rayDirection * 0.1)
            placeSwatch(planeInformation: (heading: heading, position: position), forPlacement: forPlacement)
            return
        }else{
//            state.lidarDidFindWall = false
            return
            //                    placeSwatch(planeInformation: self.swatchPlacementValuesForLidarDevicePosition)
        }
    }
}
