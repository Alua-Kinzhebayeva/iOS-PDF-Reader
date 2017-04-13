# iOS-PDF-Reader
[![Version](https://img.shields.io/cocoapods/v/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![License](https://img.shields.io/cocoapods/l/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Platform](https://img.shields.io/cocoapods/p/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

PDF Reader for iOS written in Swift
* Fast and lightweight
* Thumbnail bar on the bottom to navigate to a specific page
* Print button on the top right

![](https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/master/Screenshots/Screenshot1.png)
![](https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/master/Screenshots/Screenshot2.png)

## Requirements

- iOS 8.0+

## Installation

### CocoaPods

To install it, simply add the following line to your **Podfile**:

```ruby
pod 'PDFReader'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 1.0 or newer.

### Carthage

To install it, simply add the following line to your **Cartfile**:

```ogdl
github "Alua-Kinzhebayeva/iOS-PDF-Reader"
```

Run `carthage update` to build the framework and drag the built `PDFReader.framework` into your Xcode project.

## Usage

### Import Framework
```swift
import PDFReader
```

### Create a PDFDocument

##### From a file URL
```swift
let documentFileURL = Bundle.main.url(forResource: "Cupcakes", withExtension: "pdf")!
let document = PDFDocument(url: documentFileURL)!
```

##### From a remote URL
```swift
let remotePDFDocumentURLPath = "http://devstreaming.apple.com/videos/wwdc/2016/201h1g4asm31ti2l9n1/201/201_internationalization_best_practices.pdf"
let remotePDFDocumentURL = URL(string: remotePDFDocumentURLPath)!
let document = PDFDocument(url: documentRemoteURL)!
```

##### From Data
```swift
let document = PDFDocument(fileData: fileData, fileName: "Sample PDF")!
```

### Display a PDFDocument
```swift
let readerController = PDFViewController.createNew(with: document)
navigationController?.pushViewController(readerController, animated: true)
```

## Customizations

#### Controller Title
```swift
PDFViewController.createNew(with: document, title: "Favorite Cupcakes")
```

#### Background Color
```swift
controller.backgroundColor = .white
```

#### Action Button Image and Action

##### Available Action Styles

```swift
/// Action button style
public enum ActionStyle {
    /// Brings up a print modal allowing user to print current PDF
    case print

    /// Brings up an activity sheet to share or open PDF in another app
    case activitySheet

    /// Performs a custom action
    case customAction((Void) -> ())
}
```

```swift
let actionButtonImage = UIImage(named: "cupcakeActionButtonImage")
PDFViewController.createNew(with: document, title: "Favorite Cupcakes", actionButtonImage: actionButtonImage, actionStyle: .activitySheet)

```      

#### Override the default backbutton

```swift
/// Create a button to override the default behavior of the backbutton.  In the below example we create a cancel button which will call our myCancelFunc method on tap.
let myBackButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action:  #selector(self.myCancelFunc(_:)))
/// Provide your button to createNew using the backButton parameter.  The PDFViewController will then use your button instead of the default backbutton.
PDFViewController.createNew(with: document, title: "Favorite Cupcakes", backButton: myBackButton)

```

#### Do not load the thumbnails in the controller

```swift
let controller = PDFViewController.createNew(with: document, isThumbnailsEnabled: false)
```


#### Change scroll direction of the pages from left to right to top to bottom

```swift
controller.scrollDirection = .vertical
```


## Acknowledgements

Inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
