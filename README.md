# iOS-PDF-Reader
[![Version](https://img.shields.io/cocoapods/v/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![License](https://img.shields.io/cocoapods/l/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Platform](https://img.shields.io/cocoapods/p/PDFReader.svg?style=flat)](http://cocoapods.org/pods/PDFReader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

PDF Reader for iOS written in Swift

<img src="https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/master/Screenshot1.png" alt="Example" style="width: 690px;" />

<img src="https://raw.githubusercontent.com/Alua-Kinzhebayeva/iOS-PDF-Reader/master/Screenshot2.png" alt="Example" style="width: 690px;" />

## Installation

[CocoaPods]: http://cocoapods.org

To install it, simply add the following line to your **Podfile**:

```ruby
pod 'PDFReader'
```

You will also need to make sure you're opting into using frameworks:

```ruby
use_frameworks!
```

Then run `pod install` with CocoaPods 1.0 or newer.

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
# TODO
- Displaying two pages in landscape orientation

# Acknowledgements

inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
