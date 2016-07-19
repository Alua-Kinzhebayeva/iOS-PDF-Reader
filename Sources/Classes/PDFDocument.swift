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
    
    let fileURL: NSURL
    let coreDocument: CGPDFDocument
    
    /**
     Returns a newly initialized document which is located on the file system.
     
     - parameter fileURL: the file URL where the `.pdf` document exists on the file system
     
     - returns: A newly initialized `PDFDocument`.
     */
    public init(fileURL: NSURL) {
        self.fileURL = fileURL
        guard let fileName = fileURL.lastPathComponent else { fatalError() }
        self.fileName = fileName
        
        guard let coreDocument = CGPDFDocumentCreateWithURL(fileURL) else { fatalError() }
        self.coreDocument = coreDocument
        pageCount = CGPDFDocumentGetNumberOfPages(coreDocument)
        
        for pageNumber in 1...pageCount {
            let backgroundImage = self.imageFromPDFPage(pageNumber)
            PDFViewController.images.setObject(backgroundImage, forKey: pageNumber)
        }
    }
    
    func allPageImages() -> [UIImage] {
        return (0..<pageCount).flatMap({ getPDFPageImage($0 + 1) })
    }
    
    func getPDFPageImage(pageNumber: Int) -> UIImage {
        if let image = PDFViewController.images.objectForKey(pageNumber) as? UIImage {
            return image
        } else {
            let image = self.imageFromPDFPage(pageNumber)
            PDFViewController.images.setObject(image, forKey: pageNumber)
            return image
        }
    }
    
    private func imageFromPDFPage(pageNumber: Int) -> UIImage {
        let page = CGPDFDocumentGetPage(coreDocument, pageNumber)
        // Determine the size of the PDF page.
        var pageRect = CGPDFPageGetBoxRect(page, CGPDFBox.MediaBox)
        let scalingConstant: CGFloat = 240
        let pdfScale = min(scalingConstant/pageRect.size.width, scalingConstant/pageRect.size.height)
        pageRect.size = CGSizeMake(pageRect.size.width * pdfScale, pageRect.size.height * pdfScale)
        
        /*
         Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
         */
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()
        
        // First fill the background with white.
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context,pageRect)
        
        CGContextSaveGState(context)
        // Flip the context so that the PDF page is rendered right side up.
        CGContextTranslateCTM(context, 0.0, pageRect.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        CGContextScaleCTM(context, pdfScale, pdfScale)
        CGContextDrawPDFPage(context, page)
        CGContextRestoreGState(context)
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return backgroundImage
    }
}
