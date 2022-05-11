import Combine
import AVFoundation

final class CameraAuthorizationController: ObservableObject {
    
    static let shared = CameraAuthorizationController()
    
    @Published
    private (set) var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    func requestAccess(completion: @escaping (Bool) -> Void = { _ in }) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] authorized in
            DispatchQueue.main.async {
                self?.refreshStatus()
                completion(authorized)
            }
        }
    }
    
    var hasCameraAccess: Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .denied, .notDetermined, .restricted:
            return false
        @unknown default:
            fatalError()
        }
    }
    
    private func refreshStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
}
