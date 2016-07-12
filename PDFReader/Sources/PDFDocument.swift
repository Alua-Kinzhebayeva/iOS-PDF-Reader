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
    let fileURL: URL
    let thePDFDocRef: CGPDFDocument
    let pdfPreprocessor = PDFPreprocessor()
    
    public init(tempURL: URL) {
        guard let fileName = tempURL.lastPathComponent else { fatalError() }
        guard let tempPath = tempURL.path else { fatalError() }
        
        self.fileName = fileName
        self.fileURL = try! pdfPreprocessor.fileFolderURL(fileName).appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: tempPath) {
            let file = try? Data(contentsOf: URL(fileURLWithPath: tempPath))
            pdfPreprocessor.savePDF(fileName, pdf: file!)
        }
        
        let docURLRef = self.fileURL as CFURL
        guard let thePDFDocRef = CGPDFDocument(docURLRef) else { fatalError() }
        self.thePDFDocRef = thePDFDocRef
        pageCount = thePDFDocRef.numberOfPages
        
        pdfPreprocessor.preprocessPDF(fileName)
    }
    
    func allPageImages() -> [UIImage] {
        return (0..<pageCount).flatMap({ pdfPreprocessor.getPDFPageImageSmall(self.fileName, page: $0 + 1) })
    }
}
