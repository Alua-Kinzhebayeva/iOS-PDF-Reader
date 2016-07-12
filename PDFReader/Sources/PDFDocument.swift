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
    let fileName: String
    let fileURL: NSURL
    let thePDFDocRef: CGPDFDocument
    let pdfPreprocessor = PDFPreprocessor()
    
    init(tempURL: NSURL) {
        guard let fileName = tempURL.lastPathComponent else { fatalError() }
        guard let tempPath = tempURL.path else { fatalError() }
        
        self.fileName = fileName
        self.fileURL = pdfPreprocessor.fileFolderURL(fileName).URLByAppendingPathComponent(fileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(tempPath) {
            let file = NSData(contentsOfFile: tempPath)
            pdfPreprocessor.savePDF(fileName, pdf: file!)
        }
        
        let docURLRef = self.fileURL as CFURLRef
        guard let thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef) else { fatalError() }
        self.thePDFDocRef = thePDFDocRef
        pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef)
        
        pdfPreprocessor.preprocessPDF(fileName)
    }
    
    func allPageImages() -> [UIImage] {
        return (0..<pageCount).flatMap({ pdfPreprocessor.getPDFPageImageSmall(self.fileName, page: $0 + 1) })
    }
}
