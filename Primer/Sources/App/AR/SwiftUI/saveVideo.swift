import Photos
import UIKit

private let albumName = "Primer"



func saveVideo(url: URL,  completion: @escaping () -> Void) {
    #if APPCLIP
        completion()
    #else
    if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
        UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, nil, nil, nil)
        completion()
    } else {
        PHPhotoLibrary.shared().saveVideo(url: url, albumName: albumName) { _ in
            completion()
        }
    }
    #endif
}

func saveImage(image: UIImage,  completion: @escaping () -> Void) {
    #if APPCLIP
        completion()
    #else
    if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion()
    }else{
        PHPhotoLibrary.shared().saveImage(image: image, albumName: albumName) { _ in
            completion()
        }
    }

    #endif
}

private extension PHPhotoLibrary {

    func saveVideo(url: URL, albumName:String, completion:((PHAsset?)->())? = nil) {
        func save() {
            if let album = PHPhotoLibrary.shared().findAlbum(albumName: albumName) {
                PHPhotoLibrary.shared().saveVideo(url: url, album: album, completion: completion)
            } else {
                PHPhotoLibrary.shared().createAlbum(albumName: albumName, completion: { (collection) in
                    if let collection = collection {
                        PHPhotoLibrary.shared().saveVideo(url: url, album: collection, completion: completion)
                    } else {
                        completion?(nil)
                    }
                })
            }
        }

        if PHPhotoLibrary.authorizationStatus() == .authorized {
            save()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite,handler: { (status) in
                if status == .authorized {
                    save()
                }
                if status == .limited {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.absoluteString,nil,nil,nil)
                    completion?(nil)
                }
            })
        }
    }

    func saveImage(image: UIImage, albumName: String, completion:((PHAsset?)->())? = nil) {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        
        func save() {
            if let album = PHPhotoLibrary.shared().findAlbum(albumName: albumName) {
                PHPhotoLibrary.shared().saveImage(image: image, album: album, completion: completion)
            } else {
                PHPhotoLibrary.shared().createAlbum(albumName: albumName, completion: { (collection) in
                    if let collection = collection {
                        PHPhotoLibrary.shared().saveImage(image: image, album: collection, completion: completion)
                    } else {
                        completion?(nil)
                    }
                })
            }
        }

        if currentStatus == .authorized || currentStatus == .limited {
            save()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite,handler: { (status) in
                if status == .authorized {
                    save()
                }
                if status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    completion?(nil)
                }
            })
        }
    }

    func findAlbum(albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        guard let photoAlbum = fetchResult.firstObject else {
            return nil
        }
        return photoAlbum
    }
    
    func createAlbum(albumName: String, completion: @escaping (PHAssetCollection?)->()) {
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if success {
                guard let placeholder = albumPlaceholder else {
                    completion(nil)
                    return
                }
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album = fetchResult.firstObject else {
                    completion(nil)
                    return
                }
                completion(album)
            } else {
                completion(nil)
            }
        })
    }
    
    func saveVideo(url: URL, album: PHAssetCollection, completion:((PHAsset?)->())? = nil) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)!
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                let videoPlaceholder = createAssetRequest.placeholderForCreatedAsset else { return }
            placeholder = videoPlaceholder
            let fastEnumeration = NSArray(array: [videoPlaceholder] as [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }, completionHandler: { success, error in
            guard let placeholder = placeholder else {
                completion?(nil)
                return
            }
            if success {
                let assets:PHFetchResult<PHAsset> =  PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                let asset:PHAsset? = assets.firstObject
                completion?(asset)
            } else {
                completion?(nil)
            }
        })
    }
    
    func saveImage(image: UIImage, album: PHAssetCollection, completion:((PHAsset?)->())? = nil) {
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({

            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                print("save image album request failed")
                return
            }
            
            guard let imagePlaceholder = createAssetRequest.placeholderForCreatedAsset else {
                print("save image placeholder failed")
                return
            }
            
            placeholder = imagePlaceholder
            let fastEnumeration = NSArray(array: [imagePlaceholder] as [PHObjectPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }, completionHandler: { success, error in
            guard let placeholder = placeholder else {
                completion?(nil)
                return
            }
            if success {
                let assets:PHFetchResult<PHAsset> =  PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                let asset:PHAsset? = assets.firstObject
                completion?(asset)
            } else {
                completion?(nil)
            }
        })
    }
}

