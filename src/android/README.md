## Installation

#### SDKs

Use the Android SDK Manager to install the following items

**Tools**
* Android SDK Platform-tools
* Android SDK Build-tools

**Extras**
* Android Support Repository
* Android Support Library
* Google Play services
* Google Repository

## Usage

#### Android Studio

* Set the Compile SDK version to API 23 and the Build Tools Version to 23.0.3
* The minSdkVerion has to be 17 and the targetSdkVersion 23

#### cordova-cli
When building the application trough the cordova command-line it adds the file **project.properties** 
Make sure that this file has the project target set to **android-23**
```
target=android-23
```
