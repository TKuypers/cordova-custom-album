### iOS (XCode)
To let swift work with Cordova it is required to link **Bridging-Header.h** to your application. 
Add to following line to **Objective-C Bridging Header** in the **Build Settings** tab
```
ApplicationName/Plugins/cordova-custom-album/Bridging-Header.h
```
Or add the following line to a already existing Bridging Header:

```
#import <Cordova/CDV.h>
```

#### Additional Build settings
* Set **Embedded Content Contains Swift Code** to Yes in the **Build settings tab**



* Add the following line to the **Header Search Paths** in the **Build settings** tab
```
"$(OBJROOT)/UninstalledProducts/$(PLATFORM_NAME)/include"
```


* Add the following line to the **Runpath Search Paths** in the **Build settings tab**
```
@executable_path/Frameworks
```