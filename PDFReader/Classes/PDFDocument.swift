//
//  PDFDocument.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import CoreGraphics
import UIKit

public struct PDFDocument {
    public let pageCount: Int
    public let fileName: String
    let fileURL: NSURL
    let coreDocument: CGPDFDocument
    
    public init(tempURL: NSURL) {
        self.fileURL = tempURL
        guard let fileName = tempURL.lastPathComponent else { fatalError() }
        self.fileName = fileName
        
        guard let coreDocument = CGPDFDocumentCreateWithURL(tempURL) else { fatalError() }
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
