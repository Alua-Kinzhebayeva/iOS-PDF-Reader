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
    
    /// Name of the file stored in the file system
    public let fileName: String
    
    let fileURL: URL
    let coreDocument: CGPDFDocument
    let password: String?
    
    /// Returns a newly initialized document which is located on the file system.
    ///
    /// - parameter fileURL:  the file URL where the locked `.pdf` document exists on the file system
    /// - parameter password: password for the locked pdf
    ///
    /// - returns: A newly initialized `PDFDocument`.
    public init(fileURL: URL, password: String? = nil) {
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        
        guard let coreDocument = CGPDFDocument(fileURL as CFURL) else { fatalError() }
        
        if let password = password, let cPasswordString = password.cString(using: .utf8) {
            // Try a blank password first, per Apple's Quartz PDF example
            if coreDocument.isEncrypted && !coreDocument.unlockWithPassword("") {
                // Nope, now let's try the provided password to unlock the PDF
                if !coreDocument.unlockWithPassword(cPasswordString) {
                    print("CGPDFDocumentCreateX: Unable to unlock \(fileURL)")
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
    
    func loadPages() {
        for pageNumber in 1...self.pageCount {
            if let backgroundImage = self.imageFromPDFPage(at: pageNumber) {
                PDFViewController.images.setObject(backgroundImage, forKey: NSNumber(value: pageNumber))
            }
        }
    }
    
    var allPageImages: [UIImage] {
        return (0..<pageCount).flatMap{ getPDFPageImage(at: $0 + 1) }
    }
    
    func getPDFPageImage(at pageNumber: Int) -> UIImage? {
        if let image = PDFViewController.images.object(forKey: NSNumber(value: pageNumber)) {
            return image
        } else {
            guard let image = self.imageFromPDFPage(at: pageNumber) else { return nil }
            PDFViewController.images.setObject(image, forKey: NSNumber(value: pageNumber))
            return image
        }
    }
    
    private func imageFromPDFPage(at pageNumber: Int) -> UIImage? {
        guard let page = coreDocument.page(at: pageNumber) else { return nil }
        
        // Determine the size of the PDF page.
        var pageRect = page.getBoxRect(.mediaBox)
        let scalingConstant: CGFloat = 240
        let pdfScale = min(scalingConstant/pageRect.size.width, scalingConstant/pageRect.size.height)
        pageRect.size = CGSize(width: pageRect.size.width * pdfScale, height: pageRect.size.height * pdfScale)
        
        /*
         Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
         */
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 1)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // First fill the background with white.
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(pageRect)
        
        context.saveGState()
        // Flip the context so that the PDF page is rendered right side up.
        context.translateBy(x: 0, y: pageRect.size.height)
        context.scaleBy(x: 1, y: -1)
        
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        context.scaleBy(x: pdfScale, y: pdfScale)
        context.drawPDFPage(page)
        context.restoreGState()
        
        defer { UIGraphicsEndImageContext() }
        guard let backgroundImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        return backgroundImage
    }
}
