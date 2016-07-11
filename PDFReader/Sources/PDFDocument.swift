//
//  PDFDocument.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import CoreGraphics
import UIKit

public final class PDFDocument: NSObject, NSCoding {
    public var pageCount: NSNumber!
    var fileName: String!
    var fileURL: NSURL!
    var thePDFDocRef: CGPDFDocument!
    
    // MARK: NSCoding
    @objc required public init?(coder decoder: NSCoder) {
        pageCount = decoder.decodeObjectForKey("pageCount") as! NSNumber
        fileName = decoder.decodeObjectForKey("fileName") as! String
        fileURL = decoder.decodeObjectForKey("fileURL") as! NSURL
    }
    
     @objc public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(pageCount, forKey: "pageCount")
        coder.encodeObject(fileName, forKey: "fileName")
        coder.encodeObject(fileURL, forKey: "fileURL")
    }
    
    private init(fileName:String) {
        self.fileName = fileName
    }
    
    func allPageImages() -> [UIImage] {
        var images = [UIImage]()
        for index in 0..<pageCount.integerValue {
            if let image = PDFPreprocessor.sharedInstance.getPDFPageImageSmall(self.fileName, page: index + 1) {
                images.append(image)
            }
        }
        return images
    }
    
    func getPage(page: Int) -> (backgroundImage: UIImage?, pageRef: CGPDFPageRef?) {
        let backgroundImage = PDFPreprocessor.sharedInstance.getPDFPageImage(self.fileName, page: page+1)
        let pageRef = CGPDFDocumentGetPage(getPDFRef(), page + 1)
        return (backgroundImage, pageRef)
    }
    
    /// Creates an object wrapper around actual pdf file
    public class func createPDFDocument(fileName: String, tempPath: String, completionHandler: (success:Bool, pdfDocument:PDFDocument) -> Void) {
        let preprocessor = PDFPreprocessor.sharedInstance
        
        if NSFileManager.defaultManager().fileExistsAtPath(tempPath) {
            let file = NSData(contentsOfFile: tempPath)
            preprocessor.savePDF(fileName, pdf: file!)
        }
        
        let document = PDFDocument(fileName: fileName)
        document.fileName = fileName
        document.fileURL = preprocessor.getPathToPdfDirectory(fileName)?.URLByAppendingPathComponent(fileName)
        
        let docURLRef = document.fileURL as CFURLRef
        if let thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef) {
            document.thePDFDocRef = thePDFDocRef
            document.pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef)
        }
        
        preprocessor.preprocessPDF(fileName, completion: { (success) -> Void in
            document.saveDocument()
            completionHandler(success: success, pdfDocument: document)
        })
    }
    
    private class func archiveFilePath(fileName: String) -> NSURL? {
        guard let pathToPDF = PDFPreprocessor.sharedInstance.getPathToPdfDirectory(fileName) else { return nil }
        let achiveName = (fileName as NSString).stringByDeletingPathExtension.stringByAppendingString(".plist")
        return pathToPDF.URLByAppendingPathComponent(achiveName)
    }
    
    private func saveDocument() {
        guard let archiveFilePath = PDFDocument.archiveFilePath(fileName)?.path else { return }
        NSKeyedArchiver.archiveRootObject(self, toFile: archiveFilePath)
    }
    
    private func getPDFRef()-> CGPDFDocument {
        if thePDFDocRef == nil {
            let dir = PDFPreprocessor.sharedInstance.getPathToPdfDirectory(fileName)
            let file = dir?.URLByAppendingPathComponent(fileName).URLByAppendingPathComponent(fileName)
            let docURLRef = file as! CFURLRef
            thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef)
        }
        return thePDFDocRef
    }
}
