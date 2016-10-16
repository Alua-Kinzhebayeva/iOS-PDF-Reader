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

```swift
let documentURL = Bundle.main.url(forResource: "Cupcakes", withExtension: "pdf")!
let document = PDFDocument(fileURL: documentURL)!

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
controller.setBackgroundColor(to: UIColor.white)
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

## Acknowledgements

Inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
