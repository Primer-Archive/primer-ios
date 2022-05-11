import SwiftUI
import UIKit
import AVFoundation
import PrimerEngine
import Photos

struct CapturePreviewView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.analytics) var analytics
    
    @State private var isShowingShare: Bool = false
    
    @State private var showSaveSuccess: Bool = false
    
    @State var hasTappedToShare: Bool = false
    
    var videoFileURL: URL? = nil
    
    var image: UIImage? = nil
    
    var selectedProduct: ProductModel?
    
//    var gradient: [SwiftUI.Color] {
//        return [Color.black.opacity(0.6), Color.black.opacity(0.4), Color.black.opacity(0.3), Color.clear]
//    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    if let videoFileURL = videoFileURL {
                        GeometryReader { proxy in
                            VideoPlayerView(fileURL: videoFileURL,
                                            frameSize: CGSize(width:proxy.size.width, height:proxy.size.height),
                                            aspect: .resizeAspect)
                        }
                    } else if let image = image {
                        Image(uiImage: image).resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                            .clipped()
                    }
                }
                
                SharePopOverView(facebookAction: shareToStory(on:), instagramAction: shareToStory(on:), saveAction: save, shareAction: share, mediaType: "\(videoFileURL == nil ? "Image" : "Video")")
   
            }.edgesIgnoringSafeArea(.bottom)
            .background(BrandColors.darkBlue.color)
            
            HStack {
                SmallSystemIcon(style: .x12, isButton: true) {
                    self.presentationMode.wrappedValue.dismiss()
                }.padding(BrandPadding.Small.pixelWidth)
                Spacer()
            }
            
            ZStack {
                Rectangle()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(TemporaryPopup(labelText: "\(videoFileURL == nil ? "Saved Image" : "Saved Video")"))
                    .edgesIgnoringSafeArea(.bottom)
            }.opacity(showSaveSuccess ? 1 : 0)
        }.onDisappear {
            if !hasTappedToShare {
                if videoFileURL != nil {
                    analytics?.didCancelShare(product: selectedProduct, previewType: .appVideo)
                } else if image != nil {
                    analytics?.didCancelShare(product: selectedProduct, previewType: .appStill)
                }
            }
        }
    }
    
    // MARK: Save
    
    private func save() {
        hasTappedToShare = true
        if let videoURL = videoFileURL {
            saveVideo(url: videoURL) {
                withAnimation {
                    showSaveSuccess = true
                }
                analytics?.didSharePreview(activityType: .saveToCameraRoll, product: selectedProduct, previewType: .appVideo, social: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(700)) {
                    // set your var here
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else if let image = image {
            saveImage(image: image) {
                withAnimation {
                    showSaveSuccess = true
                }
                analytics?.didSharePreview(activityType: .saveToCameraRoll, product: selectedProduct, previewType: .appStill, social: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(700)) {
                    // set your var here
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Generic Share
    
    private func share() {
        hasTappedToShare = true
        var vc: UIActivityViewController?
        var items: [Any] = []
        if let selectedProduct = selectedProduct, let url = URL(string: "https://apps.apple.com/us/app/primer-ar-home-design/id1451986109") {
            let shareString = "What do you think of \(selectedProduct.name) by \(selectedProduct.brandName) in my space? \nDownload the Primer app to checkout more options:"
            items.append(shareString)
            items.append(url)
        }
        
        if let videoFile = videoFileURL {
            items.append(videoFile)
            vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
            vc!.completionWithItemsHandler = { (activityType, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self.analytics?.didSharePreview(activityType: activityType, product: selectedProduct, previewType: .appVideo, social: nil)
                } else {
                    self.analytics?.didCancelShare(product: selectedProduct, previewType: .appVideo)
                }
            }

            let asset = AVAsset(url: videoFile)
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)

            analytics?.didTapShareVideo(product: selectedProduct, durationTime: durationTime)
        }

        if let image = image {
            items.append(image)
            vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
            vc!.completionWithItemsHandler = { (activityType, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self.analytics?.didSharePreview(activityType: activityType, product: selectedProduct, previewType: .appStill, social: nil)
                } else {
                    self.analytics?.didCancelShare(product: selectedProduct, previewType: .appStill)
                }
            }
        }
        
        let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        var presentingViewController = scene.windows.first!.rootViewController!
        presentingViewController.modalPresentationStyle = .fullScreen
        

        if let vc = vc {
            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceView = presentingViewController.view //to set the source of your alert
                popoverController.sourceRect = CGRect(x: presentingViewController.view.bounds.midX, y: presentingViewController.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            }

            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }
            isShowingShare = true
            presentingViewController.present(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Share Post
    
    //old function, saved for future use.
    private func shareToInstagramFeed() {
        hasTappedToShare = true
        let fetchOptions = PHFetchOptions()
        self.analytics?.didSharePreview(activityType: nil, product: selectedProduct, previewType: .appVideo, social: "Instagram")
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        if let lastAsset = fetchResult.firstObject {
            let localIdentifier = lastAsset.localIdentifier
            
            let customSchemeURL = "instagram://library?LocalIdentifier=" + localIdentifier
            guard let url = URL(string: customSchemeURL) else {
                print("Unable to form customSchemeURL")
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                let instagramAppStoreURL = "https://itunes.apple.com/in/app/instagram/id389801252?mt=8"
                guard let instaURL = URL(string: instagramAppStoreURL) else {
                    print("Unable to form instaURL")
                    return
                }
                UIApplication.shared.open(instaURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    // MARK: - Share Story
    func resize(image: UIImage,maxSize: CGFloat) -> UIImage {
        // adjust for device pixel density
        let maxSizePixels = maxSize / UIScreen.main.scale
        // work out aspect ratio
        let aspectRatio =  image.size.width/image.size.height
        // variables for storing calculated data
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        if aspectRatio > 1 {
            // landscape
            width = maxSizePixels
            height = maxSizePixels / aspectRatio
        } else {
            // portrait
            height = maxSizePixels
            width = maxSizePixels * aspectRatio
        }
        // create an image renderer of the correct size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: UIGraphicsImageRendererFormat.default())
        // render the image
        newImage = renderer.image {
            (context) in
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        // return the image
        return newImage
    }
    
    private func shareToStory(on social: SocialMediaDestination) {
        hasTappedToShare = true
        
        guard let url = URL(string: social.schemeURL) else {
            print("Unable to form customSchemeURL for \(social.schemeURL)")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            let fetchOptions = PHFetchOptions()

            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            if let videoFileURL = videoFileURL {
                do {
                    let videoData = try Data(contentsOf: (videoFileURL))
                        
                    self.analytics?.didSharePreview(activityType: nil, product: selectedProduct, previewType: .appVideo, social: social.rawValue)
                    
                    DispatchQueue.main.async {
                        let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60*5)]
                            
                        UIPasteboard.general.setItems(social.videoItems(for: videoData), options: pasteboardOptions)
                            
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } catch  {
                    print("exception catch at block - while uploading video")
                }
            } else if let image = image {
                
                //for some reason, we need to redraw the image, to get it to share on instagram.
                //we don't do any actual resizing of the image
                let resizedImage = self.resize(image: image, maxSize: image.size.width)
                guard let data = resizedImage.pngData() else { return }
                    
                self.analytics?.didSharePreview(activityType: nil, product: selectedProduct, previewType: .appStill, social: social.rawValue)
                
                DispatchQueue.main.async {
                    let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60*5)]

                    UIPasteboard.general.setItems(social.imageItems(for: data), options: pasteboardOptions)

                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        } else {
            guard let appStoreURL = URL(string: social.appStoreURL) else {
                print("Unable to form URL for \(social.rawValue)")
                return
            }
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}



// MARK: - Crop Video

private func cropVideo( _ outputFileUrl: URL, callback: @escaping ( _ newUrl: URL ) -> ()) {
    let videoAsset: AVAsset = AVAsset(url: outputFileUrl)
    let clipVideoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first! as AVAssetTrack
    
    let frameRate = clipVideoTrack.nominalFrameRate
    
    // Make video to square
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = CGSize(width: clipVideoTrack.naturalSize.width, height: clipVideoTrack.naturalSize.width)
    videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
    
    // Rotate to portrait
    let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
    let transform = CGAffineTransform(
        translationX: 0.0,
        y: -(clipVideoTrack.naturalSize.height - clipVideoTrack.naturalSize.width) / 2)
    transformer.setTransform(transform, at: .zero)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
    
    instruction.layerInstructions = [transformer]
    
    videoComposition.instructions = [instruction]
    
    // Export
    
    let tempDirectoryPath = NSTemporaryDirectory()
    let filename = UUID().uuidString
    let croppedOutputFileUrl = URL(fileURLWithPath: tempDirectoryPath).appendingPathComponent("\(filename).m4v")
    
    let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
    exporter.videoComposition = videoComposition
    exporter.outputURL = croppedOutputFileUrl
    exporter.outputFileType = .m4v
    
    exporter.exportAsynchronously( completionHandler: { () -> Void in
        DispatchQueue.main.async(execute: {
            callback( croppedOutputFileUrl )
        })
    })
    
}

// MARK: - Preview

struct CapturePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CapturePreviewView(videoFileURL: NSURL(string: "http://jplayer.org/video/m4v/Big_Buck_Bunny_Trailer.m4v")! as URL)
            .background(BrandColors.sand.color)
    }
}
