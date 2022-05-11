//
//  MainView.swift
//  Primer
//
//  Created by James Hall on 10/1/20.
//  Copyright © 2020 Primer Inc. All rights reserved.
//

import Foundation




//MARK: - View Events
extension MainView{
    private func handleDeepLink(incomingURL: URL){
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
              var path = components.path else {
            return
        }
        
        self.appState.isLoadingDeepLink = true
        //app clip url
        //i.e. https://appclip.primer.com/88d83639
        if !path.contains("partners") {
            path = path.replacingOccurrences(of: "/", with: "")
            
            client.appClipData(path)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            print(error.localizedDescription)
                    }
                }, receiveValue: { data in
                    //                guard let products = data[0].products else { return }
                    
                    self.appState.currentIndex = 1
                    
                    self.appState.visibleSheet = nil
                    
                    self.appState.selectedBrandId = data.brand.id
                    
                    
                    guard let productCollection = data.productCollections.first,
                          var products = productCollection.products else {
                        return
                    }
                    
                    
                    
                    
                    
                    let productId = data.selectedProductId ?? -1
                    
                    var selectedProduct:ProductModel?
                    
                    for (index, product) in products.enumerated() {
                        if product.productType == .productWithVariations {
                            if let variations = product.variations {
                                for(idx, variation) in variations.enumerated() {
                                    if variation.id == productId {
                                        self.appState.currentIndex = Double(index + 1)
                                        self.appState.currentVariationIndex = Double(idx)
                                        analyticInstance.trackDeepLinkForProduct(product: product)
                                        selectedProduct = product
                                    }
                                }
                            }
                        }else{
                            if product.id == data.selectedProductId {
                                self.appState.currentIndex = Double(index + 1)
                                analyticInstance.trackDeepLinkForProduct(product: product)
                                self.appState.isLoadingDeepLink = false
                                selectedProduct = product
                            }
                            
                        }
                    }
                    if let selected = selectedProduct {
                        products.move(selected,to: products.startIndex)
                    }
                    
                    self.appState.productCollection = products
                    
                    if productId < 0 {
                        self.appState.currentIndex = 1
                    }
                    
                    
                })
                .store(in: &self.cancellables)
        } else {
            
            switch path {
                case let str where str.contains("partners"):
                    if incomingURL.pathComponents.count == 4 {
                        let productSlug = incomingURL.pathComponents[3]
                        
                        client.productCollections(forProductSlug: productSlug)
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: { completion in
                                switch completion {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        print(error.localizedDescription)
                                }
                            }, receiveValue: { data in
                                guard var products = data[0].products else { return }
                                self.appState.currentIndex = 1
                                
                                self.appState.visibleSheet = nil
                                
                                var selectedProduct:ProductModel?
                                for (index, product) in products.enumerated() {
                                    if product.productType == .productWithVariations {
                                        if let variations = product.variations {
                                            for(idx, variation) in variations.enumerated() {
                                                if variation.slug == productSlug {
                                                    self.appState.currentIndex = Double(index + 1)
                                                    self.appState.currentVariationIndex = Double(idx)
                                                    analyticInstance.trackDeepLinkForProduct(product: product)
                                                    selectedProduct = product
                                                }
                                            }
                                        }
                                    }else{
                                        if product.slug == productSlug {
                                            self.appState.currentIndex = Double(index + 1)
                                            analyticInstance.trackDeepLinkForProduct(product: product)
                                            self.appState.isLoadingDeepLink = false
                                            selectedProduct = product
                                        }
                                        
                                    }
                                }
                                if let selected = selectedProduct {
                                    products.move(selected,to: products.startIndex)
                                }
                                self.appState.productCollection = products
                                
                            })
                            .store(in: &self.cancellables)
                    } else if incomingURL.pathComponents.count == 3 {
                        let brandSlug = incomingURL.pathComponents[2]
                        
                        for brand in client.brandsController.value {
                            if brand.slug == brandSlug {
                                self.appState.selectedBrandId = brand.id
                                analyticInstance.trackDeepLinkForBrand(brand: brand)
                            }
                        }
                        self.appState.visibleSheet = .brandView
                    }
                default:
                    return
            }
        }
    }
}
