//
//  EngineOverlayContent.swift
//  Primer
//
//  Created by James Hall on 7/16/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import SwiftUI
import PrimerEngine
import Photos

struct EngineOverlayContent: View {
    var engineContext: EngineContext
    @Binding var appState: AppState
    @State private var recordingStartTime: TimeInterval = 0
    @State var showCameraToolTip: Bool
    @State private var isProductDetailExpanded: Bool = false
    @State var variationOffset: CGFloat = 0.0
    @State var errorWidth: CGFloat = 330.0
    
    var client: APIClient
    
    @Environment(\.analytics) var analytics
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var obscuredAmount: Double = 0.0
    
    @State private var showingVariations: Bool = false
    
    private var shouldHideDetailsCard: Bool {
        return (self.appState.engineState.swatch == nil) ||
            (self.appState.recordingState.isRecording) ||
            (self.hideProductDetailsCard)
    }
    
    @State internal var hideProductDetailsCard = false
    
    // MARK: - Body
    
    var body: some View{
        
        //get the active window so we can find the safe insets.
        let activeWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first!
        
        return ZStack (alignment:.bottom){
            
            BottomGradientView()
            
            // MARK: - Top Controls
            
            TopControlsView {
                if isDeviceIpad() {
                    Circle().frame(width: 112, height: 42).opacity(0)
                    Spacer()
                }
                
                if appState.engineState.swatch != nil {
                    MeasurementButton(isSelected: $appState.showMeasurementHelper, measurementHelper: MeasurementHelper(width: appState.engineState.swatch?.size.width, height: appState.engineState.swatch?.size.height), btnAction: {
                        analytics?.didTapMeasurementsButton()
                        withAnimation {
                            appState.showMeasurementHelper.toggle()
                        }
                    }).animation(.spring())
                }
                
                Spacer()
                
                Button(action: {
                    self.appState.engineState.resetTime = Date().timeIntervalSinceReferenceDate
                    analyticInstance.didClearSwatch()
                }) {
                    HStack(spacing: 0) {
                        LabelView(text: "Reset", style: .transparentButton)
                            .padding(.leading, BrandPadding.Medium.pixelWidth)
                        Spacer()
                        SmallSystemIcon(style: .counterClockwiseArrow)
                            .padding(.trailing, BrandPadding.Tiny.pixelWidth)
                    }
                }
                .frame(width: 112, height: 42)
                .background(ButtonColor.transparent.background)
                .cornerRadius(21)
            }
            .opacity((self.appState.recordingState.isRecording || self.isProductDetailExpanded) ? 0.0 : 1.0)
            .padding(.top, activeWindow.safeAreaInsets.top)

            productOrbs(activeWindow: activeWindow) 
        }
        .onFrame(isActive: self.appState.recordingState.isRecording, self.willDrawFrame(_:))
        .edgesIgnoringSafeArea(.all)
        .frame(alignment: .top)
        
        // MARK: - Overlays
        
        .overlay(InstructionsOverlayView(appState: self.$appState, engineContext: self.engineContext).analytics(analyticInstance))
        .overlay(LidarInteractionPrompt(appState: self.appState, engineContext: self.engineContext))
        
        // handles visibility/animations of new variation pills
        .onChange(of: self.appState.selectedProduct?.variations?.count) { (count) in
            if let variationCount = count, variationCount > 1, self.appState.engineState.swatch != nil, !self.appState.recordingState.isRecording, !hideProductDetailsCard {
                withAnimation {
                    self.showingVariations = true
                }
            } else {
                self.showingVariations = false
            }
        }
        .onChange(of: shouldHideDetailsCard) { (value) in
            withAnimation {
                self.errorWidth = (value == true) ? 330 : 520
            }
            
            if appState.selectedProduct?.variations?.count ?? -1 > 1, self.appState.engineState.swatch != nil, !self.appState.recordingState.isRecording, !hideProductDetailsCard {
                withAnimation {
                    self.showingVariations = true
                }
            }
        }
    }
    
    private func productOrbs(activeWindow: UIWindow) -> some View {
        Group {
            VStack(spacing: 10) {
                
                ZStack {
                    VStack {
                        // MARK: - AR Error Alert
                        
                        ARTrackingStatusOverlayView(appState: self.appState, engineContext: self.engineContext)
                                .frame(maxWidth: isDeviceIpad() ? errorWidth : .infinity)
                                .padding(.horizontal, isDeviceIpad() ? 160 : BrandPadding.Smedium.pixelWidth)
                                .padding(.vertical, 3)
                        
                        // MARK: - Variations
                        
                        VariationOrbs(variations: self.appState.selectedProduct?.variations ?? [], selectedVariationIndex: self.$appState.currentVariationIndex, scrollOffset: variationOffset, selectedProductID: self.appState.selectedProduct?.variations?[Int(appState.currentVariationIndex)].id ?? -1)
                            .analytics(analyticInstance)
                            .frame(maxWidth: .infinity)
                            .opacity(showingVariations ? 1 : 0)
                            .id(self.appState.selectedProduct?.id)
                    }
                }
                .frame(minHeight: 50)

                // MARK: - Product Details View
                
                ProductDetailsView(
                    isExpanded: self.$isProductDetailExpanded,
                    appState:self.$appState,
                    client:self.client,
                    product: self.appState.selectedProductForDetails,
                    isRecording: self.appState.recordingState.isRecording,
                    favorites: self.$appState.favoriteProductIDs,
                    showCameraToolTip: self.$showCameraToolTip
                ) { brandId in
                    self.appState.selectedBrandId = brandId
                    self.appState.visibleSheet = .brandView
                }
                .background(GeometryReader { proxy in
                    Color.clear
                        .preference(key: OffsetPreferenceKey.self, value: proxy.frame(in: .global).minX)
                })
                .onPreferenceChange(OffsetPreferenceKey.self, perform: { value in
                    self.variationOffset = value
                })
            }
            .opacity((self.appState.engineState.swatch == nil) ||
                (self.appState.recordingState.isRecording) ||
                (hideProductDetailsCard) ? 0 : 1)
            .analytics(analyticInstance)
            .padding(.bottom, 105)
            .padding(.top, activeWindow.safeAreaInsets.top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .colorScheme(self.appState.recordingState.isRecording ? .dark : self.colorScheme)
            
            // MARK: - Product Orbs
            
            FilterPickerView(
                appState: self.appState,
                data: self.bookendCollection(self.appState.productCollection.value),
                currentIndex: self.$appState.currentIndex,
                hasRecorded: self.$appState.hasRecorded,
                recordingState: self.appState.recordingState,
                onBeganRecording: { self.startRecording(context: self.engineContext) },
                onEndedRecording: { self.stopRecording(context: self.engineContext) },
                onTakeScreenshot: {
                    self.takeScreenshot(context: self.engineContext)
                },
                onIndexChange: { (index) in self.onIndexChange(index: index)}
            ){ (priority, product) in
                ZStack{
                    ProductOrbView(product: product,
                                   priority: priority)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .analytics(analyticInstance)
        }
        
    }
    
    // MARK: - Image Capture
    
    private func takeScreenshot(context: EngineContext) {

        //there's a slight chance you might rapidly hit the screenshot button
        //while the video is still wrapping up it's recording, let's
        //make sure we don't do that.
        if appState.isCapturingMedia {
            print("preventing screenshot while still recording")
            return
        }
        
//        #if !APPCLIP
//        appState.hasClearedCameraTip = true
//        withAnimation {
//            showCameraToolTip = false
//        }
//        #endif
//        capturingMedia = true
        appState.isCapturingMedia = true
        
        analyticInstance.captureInitiated(.appStill, for: self.appState.selectedProductForDetails)
        
        guard let product = self.appState.selectedProductForDetails else {
            
            return
        }
        
        appState.recordingState = .recording(amountComplete: 0.0)
        if let image = context.takeSnapshot() {
            appState.recordingState = .notRecording
            DispatchQueue.main.async {
                
                let overlayView = WaterMarkView(product: product,width: Int(image.size.width), height: Int(image.size.height))
                overlayView.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                overlayView.layoutIfNeeded()
                
                let size = image.size
                UIGraphicsBeginImageContext(size)
                
                let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                image.draw(in: areaSize)
                
                overlayView.layer.render(in: UIGraphicsGetCurrentContext()!)
                
                let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                
                if PHPhotoLibrary.authorizationStatus() == .authorized || PHPhotoLibrary.authorizationStatus() == .limited {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        // set your var here
                        appState.isCapturingMedia = false
                    }
                    analyticInstance.capturePreview(.appStill, for: product)
                    self.appState.visibleSheet = .imagePreview(image: newImage)
                } else {
                    appState.tempCapturedImage = newImage
                    withAnimation {
                        appState.showPhotoPermissions.toggle()
                    }
                }
            }
        }
    }


    // MARK: - Bookend Orbs
    
    private func bookendCollection(_ products: [ProductModel]) -> [ProductModel] {
        guard products.count > 0 else { return products }
        let browseLeading = ProductModel(id: -1, material: products[0].material, name: "View More")
        let browseTrailing = ProductModel(id: -2, material: products[products.count-1].material, name: "View More")
        var productArray = [ProductModel]()
        productArray.append(browseLeading)
        productArray.append(contentsOf: products)
        productArray.append(browseTrailing)
        return productArray
    }
    
    // MARK: - Recording
    
    private func startRecording(context: EngineContext) {
        
        if appState.isCapturingMedia {
            print("preventing video while still taking screenshot")
            return
        }
        
        appState.isCapturingMedia = true
        
        recordingStartTime = CACurrentMediaTime()
        context.startRecording(selectedProduct: appState.selectedProductForDetails, variationIndex: Int(appState.currentVariationIndex))
        analyticInstance.capturePreview(.appVideo, for: appState.selectedProduct)
        analyticInstance.captureInitiated(.appVideo, for: appState.selectedProduct)
        
//        #if !APPCLIP
//        appState.hasClearedCameraTip = true
//        withAnimation {
//            showCameraToolTip = false
//        }
//        #endif
        
        appState.hasRecorded = true
        withAnimation(.spring(response: 0.18, dampingFraction: 1.0, blendDuration: 0.0)) {
            appState.recordingState = .recording(amountComplete: 0.0)
        }
    }
    
    private func stopRecording(context: EngineContext) {
        
        withAnimation(.spring(response: 0.18, dampingFraction: 1.0, blendDuration: 0.0)) {
            appState.recordingState = .notRecording
            
        }
        
        context.stopRecording { url in
            analyticInstance.finishedPreviewCapture(.appVideo, for: appState.selectedProduct)
            
            if PHPhotoLibrary.authorizationStatus() == .authorized || PHPhotoLibrary.authorizationStatus() == .limited {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                    // set your var here
                    appState.isCapturingMedia = false
                }
                
                if let url = url {
                    self.appState.visibleSheet = .capturePreview(fileURL: url)
                }
            } else {
                appState.tempVideoURL = url
                withAnimation {
                    appState.showPhotoPermissions.toggle()
                }
            }
        }
    }
    
    // MARK: - Index Change
    
    private func onIndexChange(index: Double) {
        DispatchQueue.main.async {
            if (index <= 0.85 || index >= (Double(self.appState.productCollection.value.count) + 0.15)) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.hideProductDetailsCard = true
                }
                
            } else if self.hideProductDetailsCard {
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.hideProductDetailsCard = false
                }
            }
            
            //1) we are now at either the beginning or end of the list
            //  let's view more products regardless of having a swatch or not.
            if !self.appState.ignoreIndexChange && (index == 0.0 || index >= Double(self.appState.productCollection.value.count + 1)) {
                Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { timer in
                    
                    // only pop up the drawer if we know there are products present (not in a loading state)
                    if self.appState.productCollection.value.count > 0 {
                        self.appState.visibleSheet = .browser
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                            if (index == 0) {
                                self.appState.currentIndex = 1.0
                                analyticInstance.didViewMoreProductOrb(location:"start")
                            } else {
                                self.appState.currentIndex = Double(self.appState.productCollection.value.count)
                                analyticInstance.didViewMoreProductOrb(location:"end")
                            }
                        }
                    }
                }
            } else {
            // 2) We have a swatch, and we are at a new index.
                //we should update to the new index
                //so we reset the variation index IF we're not loading a deep link
                if (self.appState.engineState.swatch != nil &&
                    Int(round(self.appState.currentIndex)) != Int(round(self.appState.lastIndex))) {
                    if self.appState.visibleSheet != nil
                        &&
                        (self.appState.visibleSheet != .browser &&
                          (self.appState.lastIndex != 0 && (Int(round(self.appState.lastIndex)) != self.appState.productCollection.value.count + 1)))
                    {
                        print("setting visible sheet to nil, was \(self.appState.visibleSheet!)")
                        self.appState.visibleSheet = nil
                    }
                    self.appState.lastIndex = self.appState.currentIndex
                    self.appState.shownProductsCount += 1
                    if let product = self.appState.selectedProduct {
                        if product.productType == .product {
                            self.appState.ignoreIndexChange = false
                            self.appState.currentVariationIndex = 0
                        } else {
                            if self.appState.ignoreIndexChange {
                                self.appState.ignoreIndexChange = false
                            } else {
//                                //reset the variation index that was selected when choosing a product
                                //from the product view.
                                self.appState.currentVariationIndex = 0
                            }
                            
                        }
                    }
                }
                
            }
            
            //reset the variation when we change products,
            //but don't have a swatch posted
            if (self.appState.engineState.swatch == nil &&
                Int(round(self.appState.currentIndex)) != Int(round(self.appState.lastIndex))) {
                if self.appState.visibleSheet != nil
                    &&
                    (self.appState.visibleSheet != .browser &&
                      (self.appState.lastIndex != 0 && (Int(round(self.appState.lastIndex)) != self.appState.productCollection.value.count + 1))){
                    print("setting visible sheet to nil, was \(self.appState.visibleSheet!)")
                    self.appState.visibleSheet = nil
                }
                
                self.appState.lastIndex = self.appState.currentIndex
                if self.appState.ignoreIndexChange {
                    self.appState.ignoreIndexChange = false
                } else {
                    self.appState.currentVariationIndex = 0
                }
                
            }
        }
    }
    
    // MARK: - Media Helpers
    
    private func willDrawFrame(_ frame: DisplayLink.Frame) {
        
        let amountComplete = (frame.timestamp - recordingStartTime) / 6.0
        
        switch appState.recordingState {
            case .notRecording:
                break
            case .recording:
                appState.recordingState = .recording(amountComplete: CGFloat(amountComplete))
        }
    }
    
    
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.white
        let textFont = UIFont.systemFont(ofSize: 18 * UIScreen.main.scale, weight: .bold)
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        
        let style = NSMutableParagraphStyle()
        
        style.alignment = NSTextAlignment.center
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            .paragraphStyle: style
        ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func applyLogo(image: UIImage, atPoint point: CGPoint) -> UIImage {
        let logoImage = UIImage(named: "logo")

        let newSize = CGSize(width: logoImage!.size.width * 4, height: logoImage!.size.height * 4)   // set this to what you need
       
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let logoCenter = image.size.width * 0.5
        let adjustedCenter = (logoCenter - newSize.width / 2)
        let newY = image.size.height - (newSize.height + 180)
        logoImage?.draw(in: CGRect(origin: CGPoint(x: adjustedCenter, y: newY), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}


fileprivate struct OffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
