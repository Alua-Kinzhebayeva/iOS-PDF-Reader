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
    
    public init(tempURL: NSURL) {
        self.fileURL = tempURL
        guard let fileName = tempURL.lastPathComponent else { fatalError() }
        self.fileName = fileName
        
        guard let thePDFDocRef = CGPDFDocumentCreateWithURL(tempURL) else { fatalError() }
        self.thePDFDocRef = thePDFDocRef
        pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef)
        
        pdfPreprocessor.preprocessPDF(fileName, fileURL: tempURL)
    }
    
    func allPageImages() -> [UIImage] {
        return (0..<pageCount).flatMap({ pdfPreprocessor.getPDFPageImage(self.fileName, page: $0 + 1, document: thePDFDocRef) })
    }
}
