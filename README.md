# iOS-PDF-Reader
PDF Reader for iOS written in Swift

## Installation

[CocoaPods]: http://cocoapods.org

To install it, simply add the following line to your **Podfile**:

```ruby
pod 'PDFReader', :git => 'https://github.com/Alua-Kinzhebayeva/iOS-PDF-Reader.git'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 1.0 or newer.

## Usage

```swift
let documentURL = NSBundle.mainBundle().URLForResource("Cupcakes", withExtension: "pdf")!
let document = PDFDocument(tempURL: documentURL)

let storyboard = UIStoryboard(name: "PDFReader", bundle: NSBundle(forClass: PDFViewController.self))
let controller = storyboard.instantiateInitialViewController() as! PDFViewController
controller.document = document
controller.title = document.fileName
navigationController?.pushViewController(controller, animated: true)
```
# TODO
- Displaying two pages in landscape orientation

# Acknowledgements

inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
