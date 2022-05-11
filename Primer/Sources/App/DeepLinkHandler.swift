//
//  DeepLinkHandler.swift
//  Primer
//
//  Created by Eric Florenzano on 1/18/21.
//  Copyright © 2021 Primer Inc. All rights reserved.
//

import Combine
import Foundation
import PrimerEngine

final class DeepLinkHandler {
    private let client: APIClient
    private let analyticInstance: Analytics

    private var cancellables: Set<AnyCancellable>!
    private var appState: AppState!
    private var onAppStateChange: ((AppState) -> Void)!

    init(client: APIClient, analyticInstance: Analytics) {
        self.client = client
        self.analyticInstance = analyticInstance
    }

    public func bind(appState: AppState, cancellables: Set<AnyCancellable>, onAppStateChange: @escaping (AppState) -> Void) -> DeepLinkHandler {
        self.appState = appState
        self.cancellables = cancellables
        self.onAppStateChange = onAppStateChange
        return self
    }

    // Public-facing handle function which dispatches to more-specific handlers
    public func handle(incomingURL: URL) {
        guard let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
              let path = components.path else {
            return
        }
        self.appState.productCollection = EmptyProductRepository()
        self.appState.ignoreIndexChange = true
        self.onAppStateChange(self.appState)
        if path.contains("collections") {
            handleCollection(pathComponents: incomingURL.pathComponents)
        } else if path.contains("partners") {
            switch incomingURL.pathComponents.count {
            case 4:
                handleBrandProduct(pathComponents: incomingURL.pathComponents)
            case 3:
                handleBrand(pathComponents: incomingURL.pathComponents)
            default:
                return
            }
        } else {
            handleAppClip(components: components, path: path.replacingOccurrences(of: "/", with: ""))
        }
        return
    }

    //MARK: - Top-level handlers

    // Handles app clip
    private func handleAppClip(components: NSURLComponents, path: String) {
        self.client.appClipData(path)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: self.printReceiveCompletionFailure(completion:),
                receiveValue: { clipModel in
                    self.receiveAppClipLoaded(path: path, clipModel: clipModel)
                })
            .store(in: &self.cancellables)
    }

    // Handles brand link
    private func handleBrand(pathComponents: [String]) {
        let brandSlug = pathComponents[2]
        for brand in self.client.brandsRepo.value {
            if brand.slug == brandSlug {
                self.appState.selectedBrandId = brand.id
                self.onAppStateChange(self.appState)
                self.analyticInstance.trackDeepLinkForBrand(brand: brand)
            }
        }
        self.appState.visibleSheet = .brandView
        self.onAppStateChange(self.appState)
    }

    // Handles brand product link
    private func handleBrandProduct(pathComponents: [String]) {
        let productSlug = pathComponents[3]
        self.appState.visibleSheet = nil
        let repo = DeeplinkSlugRepository(productSlug: productSlug)
        self.appState.productCollection = repo
        self.onAppStateChange(self.appState)

        repo.refresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: self.printReceiveCompletionFailure(completion:),
                receiveValue: { products in
                    self.receiveProductRefreshed(productSlug: productSlug, products: products)
                }
            )
            .store(in: &cancellables)
    }

    // Handles product collection link
    private func handleCollection(pathComponents: [String]) {
        guard let collectionId = Int(pathComponents[2]) else {
            print("Could not parse collection id:", pathComponents[2])
            return
        }
        self.appState.visibleSheet = nil
        let repo = ProductCollectionRepository()
        repo.setCollectionId(collectionId: collectionId)
        self.appState.productCollection = repo
        self.onAppStateChange(self.appState)

        repo.refresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: self.printReceiveCompletionFailure(completion:),
                receiveValue: { products in
                    self.receiveProductCollectionRefreshed(collectionId: collectionId, products: products)
                }
            )
            .store(in: &cancellables)
    }

    //MARK: - Handler receivers

    private func receiveAppClipLoaded(path: String, clipModel: AppClipModel) {
        self.appState.currentIndex = 1
        self.appState.visibleSheet = nil
        self.appState.selectedBrandId = clipModel.brand.id
        let repo = DeeplinkAppClipRepository(appClipSlug: path)
        self.appState.productCollection = repo
        self.onAppStateChange(self.appState)

        repo.refresh()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: self.printReceiveCompletionFailure(completion:),
                receiveValue: { products in
                    self.receiveAppClipRefreshed(clipModel: clipModel, products: products)
                })
            .store(in: &cancellables)
    }

    private func receiveAppClipRefreshed(clipModel: AppClipModel, products: [ProductModel]) {
        self.appState.currentIndex = 1
        self.onAppStateChange(self.appState)

        guard let product = products.first else { return }
        if product.productType == .productWithVariations {
            if let variations = product.variations {
                for(idx, variation) in variations.enumerated() {
                    if variation.id == clipModel.selectedProductId {
                        self.appState.currentVariationIndex = Double(idx)
                        self.onAppStateChange(self.appState)
                        self.analyticInstance.trackDeepLinkForProduct(product: product)
                    }
                }
            }
        }

        self.appState.visibleSheet = nil
        self.onAppStateChange(self.appState)
    }

    private func receiveProductRefreshed(productSlug: String, products: [ProductModel]) {
        self.appState.currentIndex = 1
        self.onAppStateChange(self.appState)
        guard let product = products.first else {
            return
        }
        if product.productType == .productWithVariations {
            if let variations = product.variations {
                for(idx, variation) in variations.enumerated() {
                    if variation.slug == productSlug {
                        self.appState.currentVariationIndex = Double(idx)
                        self.onAppStateChange(self.appState)
                        self.analyticInstance.trackDeepLinkForProduct(product: product)
                    }
                }
            }
        }
    }

    private func receiveProductCollectionRefreshed(collectionId: Int, products: [ProductModel]) {
        self.appState.currentIndex = 1
        self.appState.visibleSheet = nil
        self.onAppStateChange(self.appState)
    }

    //MARK: - Utils

    private func printReceiveCompletionFailure(completion: Subscribers.Completion<Error>) {
        switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
        }
    }
}
