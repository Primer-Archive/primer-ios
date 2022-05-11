import ARKit

public struct EngineState {
    public var swatch: Swatch? = nil {
        didSet {
            if swatch == nil {
                gestureState = .inactive
                if !self.hideResizeTooltip {
                    self.hideResizeTooltip = true
                }
            }
        }
    }
    
    public var placementSwatch: Swatch? = nil {
        didSet {
            if placementSwatch == nil {
                gestureState = .inactive
                if !self.hideResizeTooltip {
                    self.hideResizeTooltip = true
                }
            }
        }
    }
    
    public var resetTime: TimeInterval = 0 {
        didSet {
            self.worldMappingStatus = .notAvailable
            self.trackingState = .notAvailable
            self.swatch = nil
        }
    }

    public var smartPlacementState: SmartPlacementState = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) ? .tapToPlace : .walkToWall

    internal (set) public var worldMappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    internal (set) public var trackingState: ARCamera.TrackingState = .notAvailable
    
    public var lidarDidFindWall: Bool = true
    public var isRunning: Bool = false
    public var lowLightWarning: Bool = false
    
    public var isLocalSwatchShadingEnabled = false
    
    internal var gestureState = GestureState.inactive
    
    public var activeGestureType: GestureType? {
        switch gestureState {
        case .inactive:
            return nil
        case .move:
            return .move
        case .resize(_, _, _, let corner):
            return .resize(corner: corner)
        case .pinch:
            return .pinch
        }
    }
    
    public var hideResizeTooltip: Bool {
        get {
            if(!UserDefaults.standard.bool(forKey: "hasShownPlacementHelper")){
               return true
            }
            return UserDefaults.standard.bool(forKey: "hideResizeTooltip")
        }
        set {
            UserDefaults.standard.set(true, forKey: "hideResizeTooltip")
        }
    }
    
    public init() {}
}

// MARK: - Smart Placement

extension EngineState {

    public enum SmartPlacementState: Equatable, Identifiable {
        case walkToWall
        case tiltPhone
        case tapToPlace

        public var id: Int {
            switch self {
            case .walkToWall:
                return 0
            case .tiltPhone:
                return 1
            case .tapToPlace:
                return 2
            }
        }
    }

}
