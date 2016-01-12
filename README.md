# cordova-custom-album

## Installing the plugin

```
cordova plugin add https://github.com/TKuypers/cordova-custom-album
```

It is required to set **Bridging-Header.h** as the **Objective-C Bridging Header** in the XCode **Build Settings** tab
Or add the following line to a already existing Bridging Header:

```
#import <Cordova/CDV.h>
```


# Usage

The functions of this plugin can be executed with the basic **cordova.exec** function

** Example **
```
cordova.exec(function(message, id){ //success }, function(error){ //error }, 'PluginName', 'functionName', [params]);
```
The plugin name is the name of this Swift Class (CustomAlbum)

## Fetching photos

** getPhotos() **

Return a JSON list containing all the photo's in the custom album

```
[
	{
		local_path: "path", 
		width: "width in pixels",
		height: "height in pixels",
		created_at: "created date",
		modified_at: "modified date",
		filename: "local filename",
		id: "local identifier"
	},
]
```

## Save a photo

** storeImage(url:String) **

Save an image from the web to the custom album

Returns the local identifier (id)


## Remove a photo

** removeImage(id:String) **

Remove an image based on the local identifier (id)

Returns the local identifier (id)