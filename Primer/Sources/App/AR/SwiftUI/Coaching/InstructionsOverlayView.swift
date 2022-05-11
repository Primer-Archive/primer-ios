
import SwiftUI
import ARKit
import PrimerEngine


// MARK: - Instruction Overlay
/**
 Houses the instruction modals for placing a swatch. `StepView` displays one time on initial use for lidar devices, and `SwatchTutorialView` modal displays for all other devices anytime a collection is loaded, but a swatch is not placed. If collection has not been loaded yet, a "Loading" pill is displayed.
 */
struct InstructionsOverlayView: View {
    @Environment(\.analytics) var analytics
    @ObservedObject private var materialCache = MaterialCache.shared
    @State private var seenLidarHelp = false
    @Binding var appState: AppState
    @State private var alertItem: AlertItem?
    var engineContext: EngineContext
    
    var isVisible: Bool {
        if AppState.canUseLidar(), UserDefaults.hasSeenLidarHelp {
            return false
        } else {
            if seenLidarHelp {
                return false
            }
            return appState.engineState.trackingState.hasSufficientTracking && appState.engineState.swatch == nil
        }
    }
    
    var isCurrentProductLoaded: Bool {
        // show video modal but with "place" button disabled if material not loaded
        if appState.productCollection.value.count > 0, let product = appState.selectedProduct {
            switch materialCache.state(for: product.material, priority: 1) {
            case .loading:
                return false
            case .loaded:
                return true
            }
        } else {
            return false
        }
    }
    
    var isCollectionLoaded: Bool {
        if appState.productCollection.value.count > 0 {
            return true
        } else {
            // show "Loading" pill, hide video modal
            return false
        }
    }
    
    var errorIsPresent: Bool {
        // check for custom low light warning
        if appState.engineState.lowLightWarning {
            return true
        } else {
            // check ARTracking responses
            switch appState.engineState.trackingState {
            case .limited(let reason):
                switch reason {
                case .excessiveMotion, .insufficientFeatures:
                    return true
                default:
                    return false
                }
            case .normal, .notAvailable:
                if !appState.engineState.lidarDidFindWall {
                    return true
                }
                return false
            }
        }
    }
    
    var body: some View {
        ZStack {
            if !errorIsPresent {
                if isVisible {
                    if isCollectionLoaded {
                        if AppState.canUseLidar() {
                            StepView(seenLidarHelp: $seenLidarHelp, engineContext: engineContext, isLoaded: isCurrentProductLoaded)
                                .frame(maxWidth: .infinity)
                                .background(BrandColors.backgroundView.color)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(radius: 12)
                                .padding(.horizontal, BrandPadding.Smedium.pixelWidth)
                                .frame(width: 280, height: 200, alignment: .center)
                                .transition(AnyTransition.opacity.animation(.default))
                        } else {
                            SwatchTutorialView(isLoading: isCurrentProductLoaded, containerWidth: isDeviceIpad() ? 340 : UIScreen.main.bounds.size.width - 40, placeSwatchAction: placeSwatch).analytics(analytics)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(radius: 12)
                                .padding(BrandPadding.Medium.pixelWidth)
                                .transition(AnyTransition.opacity.animation(.default))
                        }
                    } else {
                        loadingPill
                    }
                } else if AppState.canUseLidar(), !isCollectionLoaded {
                    // allow loading pill on lidar even if they've seen initial instruction modal
                    loadingPill
                }
            }
        }
    }
    
    var loadingPill: some View {
        VStack {
            Spacer()
            LabelView(text: "Loading", style: .bodyMedium)
                .frame(maxWidth: isDeviceIpad() ? 520 : .infinity, maxHeight: 68)
                .background(BrandColors.backgroundView.color)
                .cornerRadius(20)
                .padding(.horizontal, isDeviceIpad() ? 160 : 16)
        }.padding(.bottom, 105)
    }
    
    func placeSwatch() {
        if !UserDefaults.hasSeenLidarHelp, AppState.canUseLidar() {
            UserDefaults.hasSeenLidarHelp = true
            self.seenLidarHelp.toggle()
            return
        }
        engineContext.placeSwatch()
    }
}

// MARK: - AR Tacking Extension

extension ARCamera.TrackingState {
    
    var hasSufficientTracking: Bool {
        switch self {
        case .normal:
            return true
        case .limited:
            return false
        case .notAvailable:
            return false
        }
    }
    
    var limitedTrackingReason: String {
        switch self {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Excessive motion"
            case .relocalizing:
                return "Resuming session"
            case .insufficientFeatures:
                return "Insufficient features"
            case .initializing:
                return "Initializing"
            @unknown default:
                return "Limited Tracking"
            }
        case .normal:
            return ""
        case .notAvailable:
            return ""
        }
    }
    
    var limitedTrackingSuggestion: String {
        switch self {
        case .limited(.excessiveMotion):
            return "Move device slower"
        case .limited(.relocalizing):
            return "Wait for phone to start"
        case .limited(.insufficientFeatures):
            return "Scan room with phone"
        case .notAvailable:
            return ""
        case .limited(.initializing):
            return "Wait for phone to start"
        case .normal:
            return ""
        @unknown default:
            return "Scan room with phone"
        }
    }
}

// MARK: - AR Mapping Extension

fileprivate extension ARFrame.WorldMappingStatus {
    var hasSufficientTracking: Bool {
        switch self {
        case .notAvailable, .limited:
            return false
        case .mapped, .extending:
            return true
        @unknown default:
            return false
        }
    }
}

// MARK: - Instruction View

struct StepView: View {
    
    @Binding var seenLidarHelp: Bool
    var engineContext: EngineContext
    var isLoaded: Bool

    private var videoURL: URL? {
        if !AppState.canUseLidar() {
            return URL(string: Video.remoteIphoneInstruction.rawValue)
        } else {
            return URL(string: Video.remoteIpadInstruction.rawValue)
        }
    }

    var helpText: String {
        if !AppState.canUseLidar() {
            return "Place your \(UIDevice.current.userInterfaceIdiom == .pad ? "pad" : "phone") against your wall.\nThen tap the button below."
        } else {
            return "Tap a wall to place the swatch"
        }
    }
    
    var buttonText: String {
        if !isLoaded {
            return "Loading Materials"
        }

        if !AppState.canUseLidar() {
            return "Place Swatch"
        } else {
            return "Understood"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VideoPlayerView(fileURL: videoURL)
                .frame(width: 320, height: 220, alignment: .center)
                .background(BrandColors.navy.color)
            VStack(spacing: 20) {
                LabelView(text: helpText, style: .cardDescription)
                Button(buttonText) {
                    placeSwatch()
                }
                .disabled(!isLoaded)
                .buttonStyle(PrimaryCapsuleButtonStyle(font: LabelStyle.buttonMedium.font, cornerRadius: 10))
            }.padding(BrandPadding.Smedium.pixelWidth)
            .frame(width: 320, height: 140, alignment: .center) // Setting height ensures label doesn't clip
        }
    }
    
    
    private func placeSwatch() {
        if !UserDefaults.hasSeenLidarHelp, AppState.canUseLidar() {
            UserDefaults.hasSeenLidarHelp = true
            self.seenLidarHelp.toggle()
            return
        }
        engineContext.placeSwatch()
    }
}

//struct InstructionsOverlayView_Previews: PreviewProvider {
//    static var previews: some View {
//        InstructionsOverlayView(appState: .initialState)
//    }
//}
