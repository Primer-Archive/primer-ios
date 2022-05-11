import Combine
import Foundation
import CryptoKit

public struct CachedMaterial: Equatable {
    public var material: MaterialModel
    public var cacheMap: [URL:URL]
}


public final class MaterialCache: ObservableObject {
    
    public static let shared = MaterialCache()
    
    @Published
    private var textureStates: [URL:TextureState] = [:]
        
    private enum TextureState: Equatable {
        case loading
        case failed
        case loaded(fileURL: URL)
    }
    
    public enum ModelState {
        case loading
        case loaded(CachedMaterial)
    }
    
    public func state(for model: MaterialModel, priority: Float) -> ModelState {
        
        var map: [URL:URL] = [:]
        var isLoaded = true
        
        for url in model.textureURLs {
            guard let state = textureStates[url] else {
                loadTexture(at: url, priority: priority)
                isLoaded = false
                continue
            }
            
            switch state {
            case .loading:
                isLoaded = false
            case .failed:
                isLoaded = false
                loadTexture(at: url, priority: priority)
            case .loaded(let localURL):
                map[url] = localURL
            }
        }
        if isLoaded {
            return .loaded(CachedMaterial(material: model, cacheMap: map))
        } else {
            return .loading
        }
    }
        
    private func loadTexture(at url: URL, priority: Float) {
        if case .loading = textureStates[url] { return }
        if case .loaded = textureStates[url] { return }
        textureStates[url] = .loading
        
        let destinationURL = localFileURL(for: url)
        
        DispatchQueue.global().async {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                DispatchQueue.main.async {
                    self.textureStates[url] = .loaded(fileURL: destinationURL)
                }
            } else {
                
                let task = URLSession.shared.downloadTask(with: url) { [weak self] (fileURL, response, error) in
                    if let fileURL = fileURL {
                        self?.downloadDidFinish(for: url, fileURL: fileURL)
                    } else {
                        self?.downloadDidFail(for: url)
                    }
                }
                task.priority = priority
                task.resume()
                
                
            }
        }
        
    }
    
    private func downloadDidFinish(for url: URL, fileURL: URL) {
        let destinationURL = localFileURL(for: url)

        do {
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
        } catch(let error) {
            print("Failed to process downloaded image for url: \(url) - \(error)")
            DispatchQueue.main.async {
                self.textureStates[url] = .failed
            }
            return
        }
        
        DispatchQueue.main.async {
            self.textureStates[url] = .loaded(fileURL: destinationURL)
        }
    }
    
    private func downloadDidFail(for url: URL) {
        DispatchQueue.main.async {
            self.textureStates[url] = .failed
        }
    }
    
    private func localFileURL(for url: URL) -> URL {
        let fileExtension = "tmp"
        let filename = SHA256.hash(data: url.absoluteString.data(using: .utf8)!).description
        
        var destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        destinationURL.appendPathComponent("\(filename).\(fileExtension)")
        
        return destinationURL
    }
    
}

extension MaterialModel {
    
    var textureURLs: [URL] {
        return [
            diffuse.textureURL,
            ambientOcclusion.textureURL,
            normal.textureURL,
            metalness.textureURL,
            roughness.textureURL
        ].compactMap { $0 }
    }
    
}

extension MaterialModel.Property {
    var textureURL: URL? {
        if case .texture(let url) = content {
            return url
        } else {
            return nil
        }
    }
}

fileprivate struct CacheEntry {
    var remoteToDiskMapping: [URL:URL] = [:]
}
