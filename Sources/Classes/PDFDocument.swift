//
//  PDFDocument.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import CoreGraphics
import UIKit

/// PDF Document on the system to be interacted with
public struct PDFDocument {
    /// Number of pages document contains
    public let pageCount: Int
    
    /// Name of the PDF file, used to display on navigation titles
    public let fileName: String
    
    /// File url where this document resides
    let fileURL: URL?
    
    /// File data of the document
    let fileData: Data
    
    /// Core Graphics representation of the document
    let coreDocument: CGPDFDocument
    
    /// Password of the document
    let password: String?
    
    /// Image cache with the page index and and image of the page
    let images = NSCache<NSNumber, UIImage>()
    
    /// Returns a newly initialized document which is located on the file system.
    ///
    /// - parameter url:      file or remote URL of the PDF document
    /// - parameter password: password for the locked PDF
    ///
    /// - returns: A newly initialized `PDFDocument`
    public init?(url: URL, password: String? = nil) {
        guard let fileData = try? Data(contentsOf: url) else { return nil }
        
        self.init(fileData: fileData, fileURL: url, fileName: url.lastPathComponent, password: password)
    }
    
    /// Returns a newly initialized document from data representing a PDF
    ///
    /// - parameter fileData: data of the PDF document
    /// - parameter fileName: name of the PDF file
    /// - parameter password: password for the locked pdf
    ///
    /// - returns: A newly initialized `PDFDocument`
    public init?(fileData: Data, fileName: String, password: String? = nil) {
        self.init(fileData: fileData, fileURL: nil, fileName: fileName, password: password)
    }
    
    /// Returns a newly initialized document
    ///
    /// - parameter fileData: data of the PDF document
    /// - parameter fileURL:  file URL where the PDF document exists on the file system
    /// - parameter fileName: name of the PDF file
    /// - parameter password: password for the locked PDF
    ///
    /// - returns: A newly initialized `PDFDocument`
    private init?(fileData: Data, fileURL: URL?, fileName: String, password: String?) {
        guard let provider = CGDataProvider(data: fileData as CFData) else { return nil }
        guard let coreDocument = CGPDFDocument(provider) else { return nil }
        
        self.fileData = fileData
        self.fileURL = fileURL
        self.fileName = fileName
        
        if let password = password, let cPasswordString = password.cString(using: .utf8) {
            // Try a blank password first, per Apple's Quartz PDF example
            if coreDocument.isEncrypted && !coreDocument.unlockWithPassword("") {
                // Nope, now let's try the provided password to unlock the PDF
                if !coreDocument.unlockWithPassword(cPasswordString) {
                    print("CGPDFDocumentCreateX: Unable to unlock \(fileName)")
                }
                self.password = password
            } else {
                self.password = nil
            }
        } else {
            self.password = nil
        }
        
        self.coreDocument = coreDocument
        self.pageCount = coreDocument.numberOfPages
        self.loadPages()
    }
    
    /// Extracts image representations of each page in a background thread and stores them in the cache
    func loadPages() {
        DispatchQueue.global(qos: .background).async {
            for pageNumber in 1...self.pageCount {
                self.imageFromPDFPage(at: pageNumber, callback: { backgroundImage in
                    guard let backgroundImage = backgroundImage else { return }
                    self.images.setObject(backgroundImage, forKey: NSNumber(value: pageNumber))
                })
            }
        }
    }
    
    /// Image representations of all the document pages
    func allPageImages(callback: ([UIImage]) -> Void) {
        var images = [UIImage]()
        var pagesCompleted = 0
        for pageNumber in 0..<pageCount {
            pdfPageImage(at: pageNumber+1, callback: { (image) in
                if let image = image {
                    images.append(image)
                }
                pagesCompleted += 1
                if pagesCompleted == pageCount {
                    callback(images)
                }
            })
        }
    }
    
    /// Image representation of the document page, first looking at the cache, calculates otherwise
    ///
    /// - parameter pageNumber: page number index of the page
    /// - parameter callback: callback to execute when finished
    ///
    /// - returns: Image representation of the document page
    func pdfPageImage(at pageNumber: Int, callback: (UIImage?) -> Void) {
        if let image = images.object(forKey: NSNumber(value: pageNumber)) {
            callback(image)
        } else {
            imageFromPDFPage(at: pageNumber, callback: { image in
                guard let image = image else {
                    callback(nil)
                    return
                }
                
                images.setObject(image, forKey: NSNumber(value: pageNumber))
                callback(image)
            })
        }
    }
    
    /// Grabs the raw image representation of the document page from the document reference
    ///
    /// - parameter pageNumber: page number index of the page
    /// - parameter callback: callback to execute when finished
    ///
    /// - returns: Image representation of the document page
    private func imageFromPDFPage(at pageNumber: Int, callback: (UIImage?) -> Void) {
        guard let page = coreDocument.page(at: pageNumber) else {
            callback(nil)
            return
        }
        
        let originalPageRect = page.originalPageRect
        
        let scalingConstant: CGFloat = 240
        let pdfScale = min(scalingConstant/originalPageRect.width, scalingConstant/originalPageRect.height)
        let scaledPageSize = CGSize(width: originalPageRect.width * pdfScale, height: originalPageRect.height * pdfScale)
        let scaledPageRect = CGRect(origin: originalPageRect.origin, size: scaledPageSize)
        
        // Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
        UIGraphicsBeginImageContextWithOptions(scaledPageSize, true, 1)
        guard let context = UIGraphicsGetCurrentContext() else {
            callback(nil)
            return
        }
        
        // First fill the background with white.
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(scaledPageRect)
        
        context.saveGState()
        
        // Flip the context so that the PDF page is rendered right side up.
        let rotationAngle: CGFloat
        switch page.rotationAngle {
        case 90:
            rotationAngle = 270
            context.translateBy(x: scaledPageSize.width, y: scaledPageSize.height)
        case 180:
            rotationAngle = 180
            context.translateBy(x: 0, y: scaledPageSize.height)
        case 270:
            rotationAngle = 90
            context.translateBy(x: scaledPageSize.width, y: scaledPageSize.height)
        default:
            rotationAngle = 0
            context.translateBy(x: 0, y: scaledPageSize.height)
        }
        
        context.scaleBy(x: 1, y: -1)
        context.rotate(by: rotationAngle.degreesToRadians)
        
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        context.scaleBy(x: pdfScale, y: pdfScale)
        context.drawPDFPage(page)
        context.restoreGState()
        
        defer { UIGraphicsEndImageContext() }
        guard let backgroundImage = UIGraphicsGetImageFromCurrentImageContext() else {
            callback(nil)
            return
        }
        
        callback(backgroundImage)
    }
}

extension CGPDFPage {
    /// original size of the PDF page.
    var originalPageRect: CGRect {
        switch rotationAngle {
        case 90, 270:
            let originalRect = getBoxRect(.mediaBox)
            let rotatedSize = CGSize(width: originalRect.height, height: originalRect.width)
            return CGRect(origin: originalRect.origin, size: rotatedSize)
        default:
            return getBoxRect(.mediaBox)
        }
    }
}
