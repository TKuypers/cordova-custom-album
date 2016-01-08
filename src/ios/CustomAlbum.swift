import Foundation
import Photos


@objc(CustomAlbum) class CustomAlbum:CDVPlugin {
    
    /*
    var cmd:CDVInvokedUrlCommand? = nil;
    
    func registerGateway(command:CDVInvokedUrlCommand)
    {
        self.cmd = command
        
        let xmlString  = command.arguments[0] as! String
        let urlPath    = command.arguments[1] as! String
        let authStr    = command.arguments[2] as! String
        
        
        let url: NSURL = NSURL(string: urlPath)!
        
        let utf8str        = authStr.dataUsingEncoding(NSUTF8StringEncoding)
        let authEncoded    = utf8str?.base64EncodedStringWithOptions([])
        
        
        let req: NSMutableURLRequest = NSMutableURLRequest(URL: url)
            req.HTTPMethod           = "POST"
            req.addValue("text/xml", forHTTPHeaderField: "Content-Type")
            req.addValue("Basic \(authEncoded!)", forHTTPHeaderField: "Authorization")
        
        let data:NSData = xmlString.dataUsingEncoding(NSUTF8StringEncoding)!

        
        req.timeoutInterval = 60
        req.HTTPBody=data
        req.HTTPShouldHandleCookies=false
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(req, queue: queue, completionHandler:
        {
            (response: NSURLResponse?, data: NSData?, err: NSError?) -> Void in
           
            let command:CDVInvokedUrlCommand? = self.cmd!;
            
            if err == nil
            {
                let dataString = NSString(data:data!, encoding:NSUTF8StringEncoding) as! String
                let dataResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:dataString)
                
                self.commandDelegate?.sendPluginResult(dataResult, callbackId:command?.callbackId)
            }
            else
            {
                let errorString : String? = err!.localizedDescription
                let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:errorString)
                
                self.commandDelegate?.sendPluginResult(errorResult, callbackId:command?.callbackId)
            }

        })
    }
    
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String])
    {
        let currentElement=elementName
        
        print("Element \(currentElement)")
    }
    */



    static let albumName      = "Plameco"
    static let sharedInstance = CustomPhotoAlbum()

    var assetCollection: PHAssetCollection!

    override init() {
        super.init()

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
        PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(CustomPhotoAlbum.albumName)   // create an asset collection with the album name
            }) { success, error in
                if success {
                    self.assetCollection = self.fetchAssetCollectionForAlbum()
                } else {
                    print("error \(error)")
                }
        }
    }

    func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
        let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject as! PHAssetCollection
        }        
        return nil
    }

    func saveImage(image: UIImage, metadata: NSDictionary) {
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }

        PHPhotoLibrary.sharedPhotoLibrary().performChanges({                                                                    
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)                   
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset             
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)       
            albumChangeRequest!.addAssets([assetPlaceHolder!])                                                      
        }, completionHandler: nil)
    }

    
};
