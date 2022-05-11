import SwiftUI
import Photos
import PrimerEngine

/**
 Conforms to `NUXScreenView` but with the addition of handling for Camera Authorizations.
 */
struct NUXCameraPermissionsScreenView: NUXScreenView {
    @Environment(\.analytics) var analytics
    @ObservedObject private var authController = CameraAuthorizationController.shared
    @State private var showingAlert = false
    
    var page: NUXPage
    var onContinue: (AppState.VisibleSheet?) -> Void
    
    init(page: NUXPage, onContinue: @escaping (AppState.VisibleSheet?) -> Void) {
        self.page = page
        self.onContinue = onContinue
    }
    
    var body: some View {
        NUXScreenContentView(page: page, onContinue: request).analytics(analytics)
            .onAppear {
                if authController.hasCameraAccess {
                    self.onContinue(nil)
                }
            }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("AR brings Primer to life"),
                message: Text("To get the full experience of Primer, you should allow camera access"),
                primaryButton: .default(Text("Enable camera access")) {
                    analytics?.didTapGoToCameraSettings(from: .nux)
                    if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                },
                secondaryButton: .default(Text("Skip for now")){
                    self.onContinue(nil)
                }
            )
        }
    }
    
    func request(_ sheet: AppState.VisibleSheet? = nil) {
        authController.requestAccess(completion: { success in
            analytics?.cameraPermissionsSelected(authController.authorizationStatus.rawValue, location: .nux)
            if success {
                self.onContinue(sheet)
            } else {
                self.showingAlert = true
            }
        })
    }
}

struct NUXCameraPermissionsScreenView_Previews: PreviewProvider {
    static var previews: some View {
        NUXCameraPermissionsScreenView(page: .authorizeCamera, onContinue: {_ in })
    }
}
