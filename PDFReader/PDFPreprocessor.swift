//
//  PDFPreprocessor.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

private let _sharedInstance = PDFPreprocessor()

class PDFPreprocessor {
    
    let ROOT_FOLDER = "pdfs"
    let PAGES_FOLDER = "background_images"
    let STATUS_BAR_OFFSET = 20.0 as CGFloat
    
    class var sharedInstance: PDFPreprocessor{
        return _sharedInstance
    }
    
    //saves pdf to /pdfs/{id}/pdf_name.pdf
    func savePDF(name: String, pdf: NSData){
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0)as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(ROOT_FOLDER+"/"+name)
        
        let fileManager = NSFileManager.defaultManager()
        
        if(!fileManager.fileExistsAtPath(path))
        {
            var error: NSError?
            fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: &error)
            fileManager.createDirectoryAtPath(path.stringByAppendingPathComponent(PAGES_FOLDER), withIntermediateDirectories: false, attributes: nil, error: &error)
            if(error == nil){
               let filePath = path.stringByAppendingPathComponent(name)
                fileManager.createFileAtPath(filePath, contents: pdf, attributes: nil)


            }else {
                println("Failed to create dir: \(error!.localizedDescription)")

            }
        }
    }
    
    func getPathToPdfDirectory(name: String)->String?{
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0)as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(ROOT_FOLDER+"/"+name)
        
        let fileManager = NSFileManager.defaultManager()
        
        if(fileManager.fileExistsAtPath(path))
        {
            return path;
        }
        return nil;
    }
    
    //gets pdf from /pdfs/{id}/pdf_name.pdf
    func getPDF(name: String)->NSData{
        var error:NSError?
        let path = getPathToPdfDirectory(name)!+"/"+name
        let file = NSData(contentsOfFile: path)
        return file!
    }
    
    //saves page image to /pdfs/{id}/background_images/{page_num}.jpeg
    func savePDFPageImage(pdfName: String, pageNumber: Int, page: UIImage){
        let path = getPathToPdfDirectory(pdfName)!+"/"+PAGES_FOLDER+"/"+String(pageNumber)
        UIImageJPEGRepresentation(page, 1.0).writeToFile(path, atomically: true)
    }
    
    //reads page image from /pdfs/{id}/background_images/{page_num}.jpeg
    func getPDFPageImage(pdfName: String, page: Int) -> UIImage?{
        let path = getPathToPdfDirectory(pdfName)!+"/"+PAGES_FOLDER+"/"+String(page)
        return UIImage(named: path);
    }
    
    func sizeForPageBackgroundImage()->CGSize{
        var screenRect = UIScreen.mainScreen().bounds
        return CGSizeMake(screenRect.size.width, screenRect.size.height-STATUS_BAR_OFFSET);
    }
    
    func imageFromPDFPage(page:CGPDFPageRef, frame:CGRect)->UIImage{
        // Determine the size of the PDF page.
        var pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        var _PDFScale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height);
        pageRect.size = CGSizeMake(pageRect.size.width*_PDFScale, pageRect.size.height*_PDFScale);
    
        /*
        Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
        */
        UIGraphicsBeginImageContextWithOptions(pageRect.size, false, 1.0);
        var context = UIGraphicsGetCurrentContext();
    
    
        // First fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context,pageRect);
    
        CGContextSaveGState(context);
        // Flip the context so that the PDF page is rendered right side up.
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
    
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        CGContextScaleCTM(context, _PDFScale,_PDFScale);
        CGContextDrawPDFPage(context, page);
        CGContextRestoreGState(context);
    
        var backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    
        return backgroundImage;
    }
    
    //creates images from pdf pages in order to facilitate smooth scrolling
    func preprocessPDF(name:String, completion: (success: Bool)->Void){
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        var areImagesCreated = false;
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // create pdf page background images
            let pathToPDF = self.getPathToPdfDirectory(name)!+"/"+name
            let fileURL = NSURL(fileURLWithPath: pathToPDF)
            let docURLRef =  fileURL
            
            var thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
            
            var pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef) as Int
            var backgroundImageRect = CGRectZero
            backgroundImageRect.size = self.sizeForPageBackgroundImage()

            for i in 1...pageCount {
                
                var _PDFPage = CGPDFDocumentGetPage(thePDFDocRef, i);
                var backgroundImageData = self.imageFromPDFPage(_PDFPage, frame: backgroundImageRect)
                self.savePDFPageImage(name, pageNumber: i, page: backgroundImageData)
                
                }
            
            areImagesCreated = true;
            
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
                completion(success:areImagesCreated);
            }
        }
    }
   
    
    func printDir(){
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0)as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(ROOT_FOLDER)
        
        let filemgr = NSFileManager.defaultManager()
        let filelist = filemgr.contentsOfDirectoryAtPath(path, error: nil)
        
        for filename in filelist! {
            println(filename)
        }
    }
}