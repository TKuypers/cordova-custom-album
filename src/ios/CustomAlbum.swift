import Foundation
import Photos


@objc(CustomAlbum) class CustomAlbum:CDVPlugin {
    
    static let albumName      = "Plameco"
    static let sharedInstance = CustomAlbum()

    var assetCollection: PHAssetCollection!
    var photoAssets:PHFetchResult!
    
    //var cmd:CDVInvokedUrlCommand? = nil;
    
    override func pluginInitialize() {
        super.pluginInitialize()

        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }

        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.Authorized {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                status
            })
        }

        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            self.createAlbum()
        } else {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
 
    
    
    
    

    func requestAuthorizationHandler(status: PHAuthorizationStatus) {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
            print("trying again to create the album")
            self.createAlbum()
        } else {
            print("should really prompt the user to let them know it's failed")
        }
    }

    func createAlbum() {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(CustomAlbum.albumName)   // create an asset collection with the album name
            }) { success, error in
                if success {
                    self.assetCollection = self.fetchAssetCollectionForAlbum()
                } else {
                    print("error \(error)")
                }
        }
    }
    
    
    
    func getPhotos(command:CDVInvokedUrlCommand)
    {
        //self.cmd = command
        
        let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
        
        let dateFormatter            = NSDateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy H:mm:ss"
        
        var files = [AnyObject]()
        
        self.photoAssets = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: fetchOptions)
        self.photoAssets.enumerateObjectsUsingBlock{(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset
            {
                let asset = object as! PHAsset
       
                asset.requestContentEditingInputWithOptions(PHContentEditingInputRequestOptions()) { (input, _) in
                    let url = input!.fullSizeImageURL
                    
                    var fileNameArr = String(url).characters.split{$0 == "/"}.map(String.init)
    
                    let newItem = [
                        "local_path": (url?.absoluteString)!,
                        "width": String(asset.pixelWidth),
                        "height": String(asset.pixelHeight),
                        "created_at": dateFormatter.stringFromDate(asset.creationDate!),
                        "modified_at": dateFormatter.stringFromDate(asset.modificationDate!),
                        "filename": fileNameArr[(fileNameArr.count-1)],
                        "id": String(asset.localIdentifier),
                    ]
                    
                    files.append(newItem)
                    
                    // when we're done
                    if count == (self.photoAssets.count-1)
                    {
                        let dataString = JSON(files).rawString()
                        let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:dataString)
                        self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                    }
                }
            
            }
        }
    
    }
    
    
    
    func storeImage(command:CDVInvokedUrlCommand)
    {
        //self.cmd = command
            
        let urlString = command.arguments[0] as! String
        
        let imgURL:NSURL         = NSURL(string: urlString)!
        let request:NSURLRequest = NSURLRequest(URL: imgURL)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler:
        {
            (response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
            
                if error == nil
                {
                    let img:UIImage = UIImage(data:data!)!
                    self.saveImage(img, command: command)
                }
        })
            
    }
    
    

    func fetchAssetCollectionForAlbum() -> PHAssetCollection!
    {
        let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", CustomAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject as! PHAssetCollection
        }        
        return nil
    }
    
    
    
    
    func fetchAssetWithIdentifier(id:String) -> PHAsset!
    {
        let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", id)
        let collection = PHAsset.fetchAssetsWithOptions(fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject as! PHAsset
        }
        return nil
    }
    
    
    
    
    
    
    func removeImage(command:CDVInvokedUrlCommand)
    {
        let assetId = command.arguments[0] as! String
        if let assetsToDelete  = self.fetchAssetWithIdentifier(assetId)
        {
        
            PHPhotoLibrary.sharedPhotoLibrary().performChanges(
            {
                PHAssetChangeRequest.deleteAssets([assetsToDelete])
            },
            completionHandler:
            { success, error in
          
                let dataString = assetId
                let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:dataString)
                self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
            })
        }
    }
    
    
    
    

    
    func saveImage(image: UIImage, command:CDVInvokedUrlCommand)
    {
        if assetCollection == nil
        {
            return // if there was an error upstream, skip the save
        }

        var imageIdentifier: String?
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges(
        {
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)                   
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset             
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)       
                albumChangeRequest!.addAssets([assetPlaceHolder!])
            
            imageIdentifier = assetPlaceHolder!.localIdentifier
            
            }, completionHandler:
            { (success, error) -> Void in
                if success
                {
                    let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:imageIdentifier)
                    self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                }
                else
                {
                    let errorString : String? = error!.localizedDescription
                    let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:errorString)
                    
                    self.commandDelegate?.sendPluginResult(errorResult, callbackId:command.callbackId)
                }
            })
    }

    
};
