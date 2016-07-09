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
    private let STATUS_BAR_OFFSET: CGFloat = 20.0
    
    static var sharedInstance = PDFPreprocessor()
    
    init() {
        guard let path = documentsDirectory.URLByAppendingPathComponent(ROOT_FOLDER).path else { fatalError() }
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(path) {
            do {
                try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    //saves pdf to /pdfs/{id}/pdf_name.pdf
    func savePDF(name: String, pdf: NSData) {
        guard let path = documentsDirectory.URLByAppendingPathComponent(ROOT_FOLDER).URLByAppendingPathComponent(name).path else { fatalError() }
        
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(path) {
            do {
                try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
                try fileManager.createDirectoryAtPath((path as NSString).stringByAppendingPathComponent(PAGES_FOLDER), withIntermediateDirectories: false, attributes: nil)
                let filePath = (path as NSString).stringByAppendingPathComponent(name)
                fileManager.createFileAtPath(filePath, contents: pdf, attributes: nil)
            } catch let error as NSError {
                print("Failed to create dir: \(error.localizedDescription)")
            }
        }
    }
    
    func getPathToPdfDirectory(name: String) -> NSURL? {
        let pathURL = documentsDirectory.URLByAppendingPathComponent(ROOT_FOLDER).URLByAppendingPathComponent(name)
        if let path = pathURL.path where NSFileManager.defaultManager().fileExistsAtPath(path) {
            return pathURL
        } else {
            return nil
        }
    }
    
    //gets pdf from /pdfs/{id}/pdf_name.pdf
    func getPDF(name: String) -> NSData {
        guard let path = getPathToPdfDirectory(name)?.URLByAppendingPathComponent(name).path else { fatalError() }
        return NSData(contentsOfFile: path)!
    }
    
    //saves page image to /pdfs/{id}/background_images/{page_num}.jpeg
    private func savePDFPageImage(pdfName: String, pageNumber: Int, page: UIImage) {
        guard let path = getPathToPdfDirectory(pdfName)?.URLByAppendingPathComponent(PAGES_FOLDER).URLByAppendingPathComponent(String(pageNumber)).path else { fatalError() }
        UIImageJPEGRepresentation(page, 1.0)!.writeToFile(path, atomically: true)
    }
    
    //reads page image from /pdfs/{id}/background_images/{page_num}.jpeg
    func getPDFPageImage(pdfName: String, page: Int) -> UIImage? {
        guard let path = getPathToPdfDirectory(pdfName)?.URLByAppendingPathComponent(PAGES_FOLDER).URLByAppendingPathComponent(String(page)).path else { fatalError() }
        return UIImage(named: path)
    }
    
    private func sizeForPageBackgroundImage() -> CGSize {
        let screenRect = UIScreen.mainScreen().bounds
        return CGSizeMake(screenRect.size.width, screenRect.size.height-STATUS_BAR_OFFSET)
    }
    
    private func imageFromPDFPage(page:CGPDFPageRef, frame:CGRect) -> UIImage {
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
    func preprocessPDF(name:String, completion: (success: Bool) -> Void) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        var areImagesCreated = false
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // create pdf page background images
            guard let pathToPDF = self.getPathToPdfDirectory(name)?.URLByAppendingPathComponent(name).path else { fatalError() }
            let fileURL = NSURL(fileURLWithPath: pathToPDF)
            let docURLRef =  fileURL
            
            let thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
            
            let pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef) as Int
            var backgroundImageRect = CGRectZero
            backgroundImageRect.size = self.sizeForPageBackgroundImage()

            for i in 1...pageCount {
                let PDFPage = CGPDFDocumentGetPage(thePDFDocRef, i)
                let backgroundImageData = self.imageFromPDFPage(PDFPage!, frame: backgroundImageRect)
                self.savePDFPageImage(name, pageNumber: i, page: backgroundImageData)
            }
            
            areImagesCreated = true
            
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
                completion(success:areImagesCreated)
            }
        }
    }
    
    private var documentsDirectory: NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }
}