# cordova-custom-album

## Installing the plugin

```
cordova plugin add https://github.com/TKuypers/cordova-custom-album
```
See the platform independent folders for additional installation instructions

## Functions

### requestAuthorization()
Requests authorization to add a album

onSuccess/onError
```
"requestAuthorization"
```

### createAlbum(albumName:String) 
Creates a album if it doesn't already exists

onSuccess/onError
```
"createAlbum"
```


### getPhotos()
Gets all the photo information from the native album

onSuccess
```
[
	{
		"width": "0",
	    "height": "0",
	    "created_at": "dd-MM-yyyy H:mm:ss",
	    "modified_at": "dd-MM-yyyy H:mm:ss",
	    "id": "localIdentifier",
	    "filename":"name"
	},
    {
    	...
    }
]
```

onError
```
"no assets found"
```


### storeImage(url:String, reference:String)
Stores a online image into the native album

onSuccess
```
["localIdentifier", "reference"]
```

onError
```
"localizedError"
```


### removeImage(localIdentifiers:Array)
Removes the image from the native album

onSuccess
```
"0 elements deleted"
```


### loadImage(localIdentifier:String)
Gets the local (accessible) path to the image. If the normal path is not accessible (iOS) then it creates a temporary copy.
The function uses a queue to prevent loading a lot of images at the same time.

onSuccess
```
{
	 "img_path": "imagePath",
     "thumb_path": "thumbnailPath",
     "filename": "filename",
     "id": "localIdentifier"
}
```

onError
```
"localIdentifier"/"could not create image"
```