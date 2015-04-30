# iOS-PDF-Reader
PDF Reader for iOS written in Swift

# Example
First use. Case when pdf has been just downloaded.
```swift
var tempPath = NSBundle.mainBundle().pathForResource("mongodb", ofType: "pdf")
PDFDocument.createPDFDocument("mongodb.pdf", password: "", tempPath: tempPath!, deleteOriginalFile: false,completionHandler: { (success, pdfDocument) -> Void in
            //once processing is done, a callback is called to perform potential UI updates
            var rootViewController = PDFViewController(document: pdfDocument)
            self.window?.rootViewController = rootViewController
          })
```
Second and subsequent uses
```swift
var pdfDoc = PDFDocument.getPDFDocument("mongodb.pdf",password: "")
var rootViewController = PDFViewController(document: pdfDoc)
```
# TODO
- Handling PDFs with password
- ThumbView at the page bottom
- Displaying two pages in landscape orientation

# Acknowledgements

inspired by PDF Reader https://github.com/vfr/Reader and Apple's example on TiledScrollView
