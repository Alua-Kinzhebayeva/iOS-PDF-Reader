//
//  PDFDocument.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

class PDFDocument: NSCoding {
    
    var _guid: String!
    
    var _fileDate: NSDate!
    
    var _lastOpen: NSDate!
    
    var _fileSize: NSNumber!
    
    var _pageCount: NSNumber!
    
    var _pageNumber: NSNumber!
    
    var _bookmarks: NSMutableIndexSet!
    
    var _fileName: String!
    
    var _password: String!
    
    var _fileURL: NSURL!
    
    var thePDFDocRef: CGPDFDocument!
    
    // MARK: NSCoding
    
    @objc required convenience init(coder decoder: NSCoder) {
        self.init()
        self._guid = decoder.decodeObjectForKey("guid") as! String
        self._fileDate = decoder.decodeObjectForKey("fileDate") as! NSDate
        self._lastOpen = decoder.decodeObjectForKey("lastOpen") as! NSDate
        self._fileSize = decoder.decodeObjectForKey("fileSize") as! NSNumber
        self._pageCount = decoder.decodeObjectForKey("pageCount") as! NSNumber
        self._pageNumber = decoder.decodeObjectForKey("pageNumber") as! NSNumber
        self._bookmarks = decoder.decodeObjectForKey("bookmarks") as! NSMutableIndexSet
        self._fileName = decoder.decodeObjectForKey("fileName") as! String
        self._password = decoder.decodeObjectForKey("password") as! String
        self._fileURL = decoder.decodeObjectForKey("fileURL") as! NSURL
    }
    
     @objc func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self._guid, forKey: "guid")
        coder.encodeObject(self._fileDate, forKey: "fileDate")
        coder.encodeObject(self._lastOpen, forKey: "lastOpen")
        coder.encodeObject(self._fileSize, forKey: "fileSize")
        coder.encodeObject(self._pageCount, forKey: "pageCount")
        coder.encodeObject(self._pageNumber, forKey: "pageNumber")
        coder.encodeObject(self._bookmarks, forKey: "bookmarks")
        coder.encodeObject(self._fileName, forKey: "fileName")
        coder.encodeObject(self._password, forKey: "password")
        coder.encodeObject(self._fileURL, forKey: "fileURL")
    }
    
    init(){}
    
    init(fileName:String, password: String){
        self._fileName = fileName
        self._password = password
    }
    
    /*
        TODO page count
        TODO page image
        TODO keep reference to CGPDFDocumentRef
        TODO get reference to CGPDFPageRef for page
        TODO archive and unarchive secondary task
    */
    
    class func isPDF(filePath:String)->Bool{
        var state = false;
        
//        if !filePath.isEmpty// Must have a file path
//        {
//            var path = filePath.fileSystemRepresentation()
//            
//            var fd = open(path, O_RDONLY) // Open the file
//            
//            if (fd > 0) // We have a valid file descriptor
//            {
//                var sig : char = [1024] // File signature buffer
//                
//                ssize_t len = read(fd, (void *)&sig, sizeof(sig));
//                
//                state = (strnstr(sig, "%PDF", len) != NULL);
//                
//                close(fd); // Close the file
//            }
//        }
        
        return state;
    }
    //= CGPDFDocumentCreateWithURL(docURLRef)
    func getPDFRef()-> CGPDFDocument{
        if(self.thePDFDocRef == nil){
            let docURLRef = self._fileURL as CFURLRef
            self.thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
            return CGPDFDocumentCreateWithURL(docURLRef)
        }
        return self.thePDFDocRef;
    }
    
    func getPage(page: Int)->(backgroundImage: UIImage, pageRef: CGPDFPageRef){
        var backgroundImage = PDFPreprocessor.sharedInstance.getPDFPageImage(self._fileName, page: page+1)
        var pageRef = CGPDFDocumentGetPage(getPDFRef(), page+1);
        return (backgroundImage!, pageRef)
        
    }
    
    /*
        this function creates an object wrapper around actual pdf file
    */
    //TODO add error param
    class func createPDFDocument(fileName:String, password:String, tempPath:String, deleteOriginalFile: Bool, completionHandler:(success:Bool, pdfDocument:PDFDocument)-> Void){
        
        var preprocessor = PDFPreprocessor.sharedInstance
        
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(tempPath)
        {
            let file = NSData(contentsOfFile: tempPath)
            preprocessor.savePDF(fileName, pdf: file!)
            
        } else {
                //WARNING ORIGINAL FILE NOT FOUND
        }
        
        if deleteOriginalFile {
            var error : NSError?
            fileManager.removeItemAtPath(tempPath, error: &error)
            if error != nil {
                //WARNING COULD NOT DELETE ITEM
            }
        }
        
        var document = PDFDocument(fileName: fileName, password: password)
        //
        document._guid = "1"//[ReaderDocument GUID]; // Create a document GUID
        
        document._password = password // pdf password
        
        document._bookmarks = NSMutableIndexSet.new(); // bookmarks
        
        document._pageNumber = 1 // current page
        
        document._fileName = fileName; // File name
        
        var pathToFile = preprocessor.getPathToPdfDirectory(fileName)
        pathToFile =  pathToFile?.stringByAppendingPathComponent(fileName)
        
        document._fileURL = NSURL(fileURLWithPath: pathToFile!)
        
        var docURLRef = document._fileURL as CFURLRef
        
        //TODO take into consideration password
        var thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)//CGPDFDocumentCreateX(docURLRef, _password);
        
        if (thePDFDocRef != nil) // Get the number of pages in the document
        {
            document.thePDFDocRef = thePDFDocRef
            
            document._pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
            
        }
        else // Cupertino, we have a problem with the document
        {
//            NSAssert(NO, @"CGPDFDocumentRef == NULL");
        }
        
        document._lastOpen = NSDate.new()//[NSDate dateWithTimeIntervalSinceReferenceDate:0.0]; // Last opened
        
        let fileAttributes : NSDictionary?  = fileManager.attributesOfItemAtPath(document._fileURL.absoluteString!, error: nil)//[fileManager attributesOfItemAtPath:fullFilePath error:NULL];
        
        document._fileDate = fileAttributes!.valueForKey(NSFileModificationDate) as! NSDate //objectForKey:NSFileModificationDate]; // File date
        
        document._fileSize = fileAttributes!.valueForKey(NSFileSize) as! NSNumber // File size (bytes)
//
        
        preprocessor.preprocessPDF(fileName, completion: { (success) -> Void in
            completionHandler(success: success, pdfDocument: document)
        })
        
    }
    
    //TODO
    func pageCount()-> NSNumber{
        return self._pageCount;
    }


}
