# iOS-PDF-Reader
[![Version](https://img.shields.io/cocoapods/v/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![License](https://img.shields.io/cocoapods/l/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Platform](https://img.shields.io/cocoapods/p/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

PDF Reader for iOS written in Swift
* Fast and lightweight
* Thumbnail bar on the bottom to navigate to a specific page
* Print button on the top right

<img src="https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/swift2.3/Screenshots/Screenshot1.png" alt="Example" style="width: 690px;" />

<img src="https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/swift2.3/Screenshots/Screenshot2.png" alt="Example" style="width: 690px;" />

## Requirements

- iOS 9.0+

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

```swift
let documentURL = NSBundle.mainBundle().URLForResource("Cupcakes", withExtension: "pdf")!
let document = PDFDocument(fileURL: documentURL)

let storyboard = UIStoryboard(name: "PDFReader", bundle: NSBundle(forClass: PDFViewController.self))
let controller = storyboard.instantiateInitialViewController() as! PDFViewController
controller.document = document
controller.title = document.fileName
navigationController?.pushViewController(controller, animated: true)
```
## Customizations

Customize the action button image of the right menu bar item
```swift
controller.actionButtonImage = UIImage(named: "printButtonImage")
```

Customize the action button by replacing the UIBarButtonItem displayed with your own
```swift
controller.actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(myController.sharePDF(_:)))
```        

## Acknowledgements

inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
