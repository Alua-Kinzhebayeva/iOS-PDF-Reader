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
    private let ROOT_FOLDER = "pdfs"
    private let PAGES_FOLDER = "background_images"
    private let PAGES_FOLDER_SMALL = "background_images_small"
    
    private let cachesDirectory = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
    
    var rootFolder: NSURL {
        return cachesDirectory.URLByAppendingPathComponent(ROOT_FOLDER)
    }
    
    func fileFolderURL(name: String) -> NSURL {
        return rootFolder.URLByAppendingPathComponent(name)
    }
    
    private func fileFolderImagesURL(name: String) -> NSURL {
        return fileFolderURL(name).URLByAppendingPathComponent(PAGES_FOLDER)
    }
    
    private func fileFolderImagesURL(name: String, page: Int) -> NSURL {
        return fileFolderImagesURL(name).URLByAppendingPathComponent(String(page))
    }
    
    private func fileFolderThumbnailImagesURL(name: String) -> NSURL {
        return fileFolderURL(name).URLByAppendingPathComponent(PAGES_FOLDER_SMALL)
    }
    
    private func fileFolderThumbnailImagesURL(name: String, page: Int) -> NSURL {
        return fileFolderThumbnailImagesURL(name).URLByAppendingPathComponent(String(page))
    }
    
    //saves pdf to /pdfs/{id}/pdf_name.pdf
    func savePDF(name: String, pdf: NSData) {
        guard let path = rootFolder.URLByAppendingPathComponent(name).path else { fatalError() }
        
        do {
            let fileManager = NSFileManager.defaultManager()
            try fileManager.removeItemAtURL(rootFolder)
            try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectoryAtPath((path as NSString).stringByAppendingPathComponent(PAGES_FOLDER), withIntermediateDirectories: false, attributes: nil)
            try fileManager.createDirectoryAtPath((path as NSString).stringByAppendingPathComponent(PAGES_FOLDER_SMALL), withIntermediateDirectories: false, attributes: nil)
            let filePath = (path as NSString).stringByAppendingPathComponent(name)
            fileManager.createFileAtPath(filePath, contents: pdf, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)")
        }
    }
    
    //gets pdf from /pdfs/{id}/pdf_name.pdf
    func getPDF(name: String) -> NSData {
        guard let path = fileFolderURL(name).URLByAppendingPathComponent(name).path else { fatalError() }
        return NSData(contentsOfFile: path)!
    }
    
    //saves page image to /pdfs/{id}/background_images/{page_num}.jpeg
    private func savePDFPageImage(pdfName: String, pageNumber: Int, page: UIImage) {
        let url = fileFolderImagesURL(pdfName, page: pageNumber)
        UIImageJPEGRepresentation(page, 1.0)?.writeToURL(url, atomically: true)
    }
    
    //saves page image to /pdfs/{id}/background_images_small/{page_num}.jpeg
    private func savePDFPageImageSmall(pdfName: String, pageNumber: Int, page: UIImage) {
        let url = fileFolderThumbnailImagesURL(pdfName, page: pageNumber)
        UIImageJPEGRepresentation(page, 1.0)?.writeToURL(url, atomically: true)
    }
    
    //reads page image from /pdfs/{id}/background_images/{page_num}.jpeg
    func getPDFPageImage(pdfName: String, page: Int) -> UIImage? {
        guard let path = fileFolderImagesURL(pdfName, page: page).path else { fatalError() }
        return UIImage(contentsOfFile: path)
    }
    
    //reads page image from /pdfs/{id}/background_images_small/{page_num}.jpeg
    func getPDFPageImageSmall(pdfName: String, page: Int) -> UIImage? {
        guard let path = fileFolderThumbnailImagesURL(pdfName, page: page).path else { fatalError() }
        return UIImage(contentsOfFile: path)
    }
    
    private func imageFromPDFPage(page: CGPDFPageRef, frame: CGRect) -> UIImage {
        // Determine the size of the PDF page.
        var pageRect = CGPDFPageGetBoxRect(page, CGPDFBox.MediaBox)
        let _PDFScale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height)
        pageRect.size = CGSizeMake(pageRect.size.width*_PDFScale, pageRect.size.height*_PDFScale)
    
        /*
        Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
        */
        UIGraphicsBeginImageContextWithOptions(pageRect.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
    
        // First fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0)
        CGContextFillRect(context,pageRect)
    
        CGContextSaveGState(context)
        // Flip the context so that the PDF page is rendered right side up.
        CGContextTranslateCTM(context, 0.0, pageRect.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
    
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        CGContextScaleCTM(context, _PDFScale,_PDFScale)
        CGContextDrawPDFPage(context, page)
        CGContextRestoreGState(context)
    
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return backgroundImage
    }
    
    //creates images from pdf pages in order to facilitate smooth scrolling
    func preprocessPDF(name: String) {
        // create pdf page background images
        guard let pathToPDF = self.fileFolderURL(name).URLByAppendingPathComponent(name).path else { fatalError() }
        let fileURL = NSURL(fileURLWithPath: pathToPDF)
        let docURLRef =  fileURL
        
        let thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
        
        let pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef) as Int
        var backgroundImageRect = CGRectZero
        backgroundImageRect.size = UIScreen.mainScreen().bounds.size
        
        for i in 1...pageCount {
            let PDFPage = CGPDFDocumentGetPage(thePDFDocRef, i)
            let backgroundImageData = self.imageFromPDFPage(PDFPage!, frame: backgroundImageRect)
            self.savePDFPageImage(name, pageNumber: i, page: backgroundImageData)
            
            let backgroundImageDataSmall = self.imageFromPDFPage(PDFPage!, frame: CGRectMake(0, 0, 240, 320))
            self.savePDFPageImageSmall(name, pageNumber: i, page: backgroundImageDataSmall)
        }
    }
}
