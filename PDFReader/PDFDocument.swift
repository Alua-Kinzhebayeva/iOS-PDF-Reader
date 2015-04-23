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

class PDFDocument: NSObject, NSCoding {
    
//    var _fileDate: NSDate!
//    
    var _lastOpen: NSDate!
//
//    var _fileSize: NSNumber!
    
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
//        self._fileDate = decoder.decodeObjectForKey("fileDate") as! NSDate
        self._lastOpen = decoder.decodeObjectForKey("lastOpen") as! NSDate
//        self._fileSize = decoder.decodeObjectForKey("fileSize") as! NSNumber
        self._pageCount = decoder.decodeObjectForKey("pageCount") as! NSNumber
        self._pageNumber = decoder.decodeObjectForKey("pageNumber") as! NSNumber
        self._bookmarks = decoder.decodeObjectForKey("bookmarks") as! NSMutableIndexSet
        self._fileName = decoder.decodeObjectForKey("fileName") as! String
        self._password = decoder.decodeObjectForKey("password") as! String
        self._fileURL = decoder.decodeObjectForKey("fileURL") as! NSURL
    }
    
     @objc func encodeWithCoder(coder: NSCoder) {
//        coder.encodeObject(self._fileDate, forKey: "fileDate")
        coder.encodeObject(self._lastOpen, forKey: "lastOpen")
//        coder.encodeObject(self._fileSize, forKey: "fileSize")
        coder.encodeObject(self._pageCount, forKey: "pageCount")
        coder.encodeObject(self._pageNumber, forKey: "pageNumber")
        coder.encodeObject(self._bookmarks, forKey: "bookmarks")
        coder.encodeObject(self._fileName, forKey: "fileName")
        coder.encodeObject(self._password, forKey: "password")
        coder.encodeObject(self._fileURL, forKey: "fileURL")
    }
    
    override init(){}
    
    init(fileName:String, password: String){
        self._fileName = fileName
        self._password = password
    }
    
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
    
    class func archiveFilePath(fileName: NSString) -> NSString{
        var pathToPDF = PDFPreprocessor.sharedInstance.getPathToPdfDirectory(fileName as String)
        if pathToPDF != nil{
            var achiveName = fileName.stringByDeletingPathExtension.stringByAppendingString(".plist")
            var archivePath = pathToPDF?.stringByAppendingPathComponent(achiveName)
            return archivePath!
        }
        return ""
    }
    
    class func unarchiveFromFileName(fileName: NSString, password: NSString) -> PDFDocument?{
        var document: PDFDocument?
        var archiveFilePath = PDFDocument.archiveFilePath(fileName)
        if !archiveFilePath.isEqualToString(""){
            document = NSKeyedUnarchiver.unarchiveObjectWithFile(archiveFilePath as String) as! PDFDocument
            document!._password = password as String
        }
        return document
    }
    
    func archiveWithFileName(fileName: NSString) -> Bool{
        var archiveFilePath = PDFDocument.archiveFilePath(fileName)
        return NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath as String)
    }
    
    func saveDocument(){
        self.archiveWithFileName(self._fileName)
    }

    func getPDFRef()-> CGPDFDocument{
        if(self.thePDFDocRef == nil){
            var dir = PDFPreprocessor.sharedInstance.getPathToPdfDirectory(self._fileName)
            var file = dir!+"/"+self._fileName
            let docURLRef = NSURL(fileURLWithPath: file) as! CFURLRef
            self.thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
            return self.thePDFDocRef
        }
        return self.thePDFDocRef;
    }
    
    func getPage(page: Int)->(backgroundImage: UIImage, pageRef: CGPDFPageRef){
        var backgroundImage = PDFPreprocessor.sharedInstance.getPDFPageImage(self._fileName, page: page+1)
        var pageRef = CGPDFDocumentGetPage(getPDFRef(), page+1);
        return (backgroundImage!, pageRef)
        
    }
    
    class func getPDFDocument(fileName:String, password:String) -> PDFDocument?{
        var document: PDFDocument?
        document = PDFDocument.unarchiveFromFileName(fileName, password: password)
        return document
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
        
        document._password = password // pdf password
        
        document._bookmarks = NSMutableIndexSet.new(); // bookmarks
        
        document._pageNumber = 1 // current page
        
        document._fileName = fileName; // File name
        
        var pathToFile = preprocessor.getPathToPdfDirectory(fileName)
        pathToFile =  pathToFile?.stringByAppendingPathComponent(fileName)
        
        document._fileURL = NSURL(fileURLWithPath: pathToFile!)
        
        var docURLRef = document._fileURL as CFURLRef
        
        //TODO take into consideration password
        var thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
        
        if (thePDFDocRef != nil) // Get the number of pages in the document
        {
            document.thePDFDocRef = thePDFDocRef
            
            document._pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
            
        }
        else
        {
            //a problem here
        }
        
        document._lastOpen = NSDate.new()
        
        preprocessor.preprocessPDF(fileName, completion: { (success) -> Void in
            
//            var error: NSError?
//            
//            let item = document._fileURL.absoluteString!
//            
//            let fileAttributes : NSDictionary?  = fileManager.attributesOfItemAtPath(item, error: &error)
//            
//            if (fileAttributes == nil) {
//                NSLog("Failed to read file size of with error \(error)")
//            }
//            
//            document._fileDate = fileAttributes!.valueForKey(NSFileModificationDate) as! NSDate
//            
//            document._fileSize = fileAttributes!.valueForKey(NSFileSize) as! NSNumber // File size (bytes)
            document.saveDocument()
            completionHandler(success: success, pdfDocument: document)
        })
        
    }
    
    func pageCount()-> NSNumber{
        return self._pageCount;
    }


}
