import Foundation
import Photos


@objc(CustomAlbum) class CustomAlbum:CDVPlugin {
    
    var albumName = ""
    
    static let sharedInstance = CustomAlbum()
    
    var assetCollection: PHAssetCollection!
    var photoAssets:PHFetchResult!
    
    //var cmd:CDVInvokedUrlCommand? = nil;
    
    override func pluginInitialize()
    {
        super.pluginInitialize()
    }
    
    
    
    
    
    func createAlbum(command:CDVInvokedUrlCommand)
    {
        let albumName  = command.arguments[0] as! String
        self.albumName = albumName
        
        let collection = self.fetchAssetCollectionForAlbum()
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {

            if let _: AnyObject = collection
            {
                self.assetCollection = collection
                
                // send succes
                let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:"createAlbum")
                self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
            }
            else
            {
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.albumName)
                    }) { success, error in
                        
                        if success
                        {
                            self.assetCollection = self.fetchAssetCollectionForAlbum()
                            
                            // send succes
                            let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:"createAlbum")
                            self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                        }
                        else
                        {
                            // error: no album
                            let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"createAlbum")
                            self.commandDelegate?.sendPluginResult(errorResult, callbackId:command.callbackId)
                            
                        }
                }
            }
        }
        else
        {
            // error: try to authorize
            self.requestAuthorization(command)
        }
    }
    
    
    
    
    func requestAuthorization(command:CDVInvokedUrlCommand)
    {
        // ask authorization
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.Authorized
        {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
               
                print(status)
                switch status
                {
                    case .Authorized:
                            // success: authorized
                            let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:"requestAuthorization")
                            self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                        break
                    
                    case .Denied:
                            let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"requestAuthorization")
                            self.commandDelegate?.sendPluginResult(errorResult, callbackId:command.callbackId)
                        break
                    
                    default:
                            // error: default
                            let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:"requestAuthorization")
                            self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                        break
                }
            })
        }
        else
        {
            print("already authorized")
            
            // success: authorized
            let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:"requestAuthorization")
            self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
        }
    }
    
    
    
    /*
    func requestAuthorizationHandler(status: PHAuthorizationStatus)
    {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
            //print("trying again to create the album")
            //self.createAlbum()
            
            // succes: authorized
        }
        else
        {
            print("should really prompt the user to let them know it's failed")
        }
    }
    */

    
    
    func getPhotos(command:CDVInvokedUrlCommand)
    {
        // check if we're authorized
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            if let assetCollection = fetchAssetCollectionForAlbum()
            {
                self.assetCollection = assetCollection

                let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
                
                let dateFormatter            = NSDateFormatter()
                    dateFormatter.dateFormat = "dd-MM-yyyy H:mm:ss"
                
                let writePath = NSURL(fileURLWithPath: NSTemporaryDirectory())//.URLByAppendingPathComponent("plameco")
                
                let checkValidation = NSFileManager.defaultManager()
                
                var files = [AnyObject]()
                
                
                self.photoAssets = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: fetchOptions)
                self.photoAssets.enumerateObjectsUsingBlock{(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                    
                    if object is PHAsset
                    {
                        
                        let asset = object as! PHAsset
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
                        {
                            asset.requestContentEditingInputWithOptions(PHContentEditingInputRequestOptions()) { (input, _) in
                            
                            
                                if let url = input!.fullSizeImageURL
                                {
                                    let fileNameArr = String(url).characters.split{$0 == "/"}.map(String.init)
                                    let filename = fileNameArr[fileNameArr.count-1]
                                    
                                    let img         = self.getAssetImage(asset)
                                    let thumbImgPath  = writePath.URLByAppendingPathComponent("thumb_\(filename)")
                                    let imgPath       = writePath.URLByAppendingPathComponent("large_\(filename)")
                                    
                                    if(!checkValidation.fileExistsAtPath(thumbImgPath.path!))
                                    {
                                        let thumbData = UIImageJPEGRepresentation(img, 0.2);
                                            thumbData?.writeToFile(thumbImgPath.path!, atomically: true)
                                    }
                                    
                                    if(!checkValidation.fileExistsAtPath(imgPath.path!))
                                    {
                                        let imgData = UIImageJPEGRepresentation(img, 1);
                                            imgData?.writeToFile(imgPath.path!, atomically: true)
                                    }
                                        
                                    let newItem = [
                                        "order":0,
                                        "img_path": imgPath.absoluteString,
                                        "thumb_path": thumbImgPath.absoluteString,
                                        "width": String(asset.pixelWidth),
                                        "height": String(asset.pixelHeight),
                                        "created_at": dateFormatter.stringFromDate(asset.creationDate!),
                                        "modified_at": dateFormatter.stringFromDate(asset.modificationDate!),
                                        "filename": filename,
                                        "id": String(asset.localIdentifier),
                                    ]
                                    
                                    
                                    files.append(newItem)
                                                                        
                                    // when we're done
                                    if files.count == (self.photoAssets.count)
                                    {
                                        print("customalbum: \(files.count)")
                                        
                                        dispatch_async(dispatch_get_main_queue())
                                        { [weak self] in
                                            
                                            if let weakSelf = self
                                            {
                                                let dataString = JSON(files).rawString()
                                                let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:dataString)
                                                weakSelf.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
                
                // check if we have files
                if self.photoAssets.count == 0
                {
                    let errorString : String? = "no assets found"
                    let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:errorString)
                    self.commandDelegate?.sendPluginResult(errorResult, callbackId:command.callbackId)
                }
            }
        }
        else
        {
            self.notAuthorized(command)
        }
    }




    func getAssetImage(asset: PHAsset) -> UIImage
    {
        let manager = PHImageManager.defaultManager()
        let option  = PHImageRequestOptions()
        option.synchronous = true
        
        var img     = UIImage()
        
        manager.requestImageForAsset(asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .AspectFit, options: option, resultHandler: {(result, info)->Void in
            img = result!
        })
        return img
    }
    
    
    
    func storeImage(command:CDVInvokedUrlCommand)
    {
        // ask authorization
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            
            let urlString       = command.arguments[0] as! String
            let customReference = command.arguments[1] as! String
            
            let imgURL:NSURL         = NSURL(string: urlString)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler:
            {
                (response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                    
                if error == nil
                {
                    let img:UIImage = UIImage(data:data!)!
                    self.saveImage(img, reference:customReference, command: command)
                }
            })
        }
        else
        {
            self.notAuthorized(command)
        }
        
    }
    
    
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection!
    {
        let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", self.albumName)
        
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
        // ask authorization
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
        {
            let assetIds       = command.arguments
            var assetsToDelete = [AnyObject]()
            
            for assetId in assetIds as! [String]
            {
                if let assetToDelete = self.fetchAssetWithIdentifier(assetId)
                {
                    assetsToDelete.append(assetToDelete)
                }
            }
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges(
            {
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            },
            completionHandler:
            { success, error in
                        
                let dataString = "\(assetsToDelete.count) elements deleted"
                let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:dataString)
                self.commandDelegate?.sendPluginResult(dataResult, callbackId:command.callbackId)
            })
        }
        else
        {
            self.notAuthorized(command)
        }
    }
    
    
    
    
    
    
    func saveImage(image: UIImage, reference:String, command:CDVInvokedUrlCommand)
    {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized
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
                        let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArray:[imageIdentifier!, reference])
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
        else
        {
            self.notAuthorized(command)
        }
    }
    
    
    
    
    func notAuthorized(command:CDVInvokedUrlCommand)
    {
        let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:"authorizationFailed")
        self.commandDelegate?.sendPluginResult(errorResult, callbackId:command.callbackId)
    }
    
    
};
