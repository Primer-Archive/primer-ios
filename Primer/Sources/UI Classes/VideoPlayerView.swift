import SwiftUI
import AVFoundation
import Combine

struct VideoPlayerView: View {
    
    var fileURL: URL?
    var frameSize: CGSize? = nil
    var aspect: AVLayerVideoGravity? = .resizeAspectFill
    
    // MARK: - Body
    
    var body: some View {
        ViewWrapper(fileURL: fileURL, aspect: aspect)
            .frame(width: self.frameSize?.width, height: self.frameSize?.height)
    }
}


fileprivate struct ViewWrapper: UIViewRepresentable {
    
    var fileURL: URL?
    
    var aspect: AVLayerVideoGravity?
    
    func makeUIView(context: UIViewRepresentableContext<ViewWrapper>) -> PlatformView {
        PlatformView()
    }
    
    func updateUIView(_ uiView: PlatformView, context: UIViewRepresentableContext<ViewWrapper>) {
        uiView.fileURL = fileURL
        
        
        uiView.aspect = aspect ?? .resizeAspectFill
    }
    
}

fileprivate final class PlatformView: UIView {
    var observer: NSKeyValueObservation?
    var indicator: UIActivityIndicatorView?
    var fileURL: URL? = nil {
        didSet {
            guard fileURL != oldValue else { return }
            reload()
        }
    }
    
    var aspect: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            guard aspect != oldValue else { return }
           
            playerLayer.videoGravity = aspect
            
        }
    }
    
    private var player: AVPlayer? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    private var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    init() {
        super.init(frame: .zero)
        if indicator == nil {
            let indicator = UIActivityIndicatorView(style: .medium)
            self.addSubview(indicator)
            indicator.startAnimating()
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            self.indicator = indicator
        }
        
        playerLayer.videoGravity = aspect
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startOver() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    private func reload() {
        
        cancellables.removeAll()
        player?.pause()
        player = nil
        playerLayer.player = nil
        observer?.invalidate()
        
        guard let url = fileURL else {
            return
        }
        
        let item = AVPlayerItem(url: url)
        
        let player = AVPlayer(playerItem: item)
        self.observer = player.currentItem?.observe(\.status, options: [.new, .old], changeHandler: { _, _ in
            if item.status == .readyToPlay {
                self.indicator?.stopAnimating()
            }
        })
        
        NotificationCenter
            .default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.startOver()
            }
            .store(in: &cancellables)
        
        playerLayer.player = player
        self.player = player
        player.play()
    }
    
}

// MARK: - Preview

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        
        // Only shows up if you hit the "Play" button in Canvas Preview
        VideoPlayerView(fileURL: Bundle.main.url(forResource: "c3", withExtension: "mov")!, frameSize: CGSize(width: 320, height: 240))
    }
}
