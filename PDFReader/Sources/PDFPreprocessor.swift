//
//  PDFPreprocessor.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit
import CoreGraphics

internal struct PDFPreprocessor {
    //reads page image from /pdfs/{id}/background_images/{page_num}.jpeg
    func getPDFPageImage(pdfName: String, page: Int, document: CGPDFDocument) -> UIImage {
        if let image = PDFViewController.images.objectForKey(page) as? UIImage {
            return image
        } else {
            let image = self.imageFromPDFPage(document, pageNumber: page)
            PDFViewController.images.setObject(image, forKey: page)
            return image
        }
    }
    
    //creates images from pdf pages in order to facilitate smooth scrolling
    func preprocessPDF(name: String, fileURL: NSURL) {
        // create pdf page background images
        guard let thePDFDocRef = CGPDFDocumentCreateWithURL(fileURL) else { fatalError() }
        let pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef) as Int
        
        for i in 1...pageCount {
            let backgroundImage = self.imageFromPDFPage(thePDFDocRef, pageNumber: i)
            PDFViewController.images.setObject(backgroundImage, forKey: i)
        }
    }
    
    private func imageFromPDFPage(document: CGPDFDocument, pageNumber: Int) -> UIImage {
        let page = CGPDFDocumentGetPage(document, pageNumber)
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
