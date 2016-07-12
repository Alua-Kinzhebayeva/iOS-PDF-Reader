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
    
    private let cachesDirectory = FileManager.default.urlsForDirectory(.cachesDirectory, inDomains: .userDomainMask).first!
    
    var rootFolder: URL {
        return try! cachesDirectory.appendingPathComponent(ROOT_FOLDER)
    }
    
    func fileFolderURL(_ name: String) -> URL {
        return try! rootFolder.appendingPathComponent(name)
    }
    
    private func fileFolderImagesURL(_ name: String) -> URL {
        return try! fileFolderURL(name).appendingPathComponent(PAGES_FOLDER)
    }
    
    private func fileFolderImagesURL(_ name: String, page: Int) -> URL {
        return try! fileFolderImagesURL(name).appendingPathComponent(String(page))
    }
    
    private func fileFolderThumbnailImagesURL(_ name: String) -> URL {
        return try! fileFolderURL(name).appendingPathComponent(PAGES_FOLDER_SMALL)
    }
    
    private func fileFolderThumbnailImagesURL(_ name: String, page: Int) -> URL {
        return try! fileFolderThumbnailImagesURL(name).appendingPathComponent(String(page))
    }
    
    //saves pdf to /pdfs/{id}/pdf_name.pdf
    func savePDF(_ name: String, pdf: Data) {
        guard let path = try! rootFolder.appendingPathComponent(name).path else { fatalError() }
        
        do {
            try FileManager.default.removeItem(at: rootFolder)
        } catch { }
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: (path as NSString).appendingPathComponent(PAGES_FOLDER), withIntermediateDirectories: false, attributes: nil)
            try FileManager.default.createDirectory(atPath: (path as NSString).appendingPathComponent(PAGES_FOLDER_SMALL), withIntermediateDirectories: false, attributes: nil)
            let filePath = (path as NSString).appendingPathComponent(name)
            FileManager.default.createFile(atPath: filePath, contents: pdf, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)")
        }
    }
    
    //gets pdf from /pdfs/{id}/pdf_name.pdf
    func getPDF(_ name: String) -> Data {
        guard let path = try! fileFolderURL(name).appendingPathComponent(name).path else { fatalError() }
        return (try! Data(contentsOf: URL(fileURLWithPath: path)))
    }
    
    //saves page image to /pdfs/{id}/background_images/{page_num}.jpeg
    private func savePDFPageImage(_ pdfName: String, pageNumber: Int, page: UIImage) {
        let url = fileFolderImagesURL(pdfName, page: pageNumber)
        let imageData = UIImageJPEGRepresentation(page, 1.0)
        let _ = try? imageData?.write(to: url, options: [.atomic])
    }
    
    //saves page image to /pdfs/{id}/background_images_small/{page_num}.jpeg
    private func savePDFPageImageSmall(_ pdfName: String, pageNumber: Int, page: UIImage) {
        let url = fileFolderThumbnailImagesURL(pdfName, page: pageNumber)
        let imageData = UIImageJPEGRepresentation(page, 1.0)
        let _ = try? imageData?.write(to: url, options: [.atomic])
    }
    
    //reads page image from /pdfs/{id}/background_images/{page_num}.jpeg
    func getPDFPageImage(_ pdfName: String, page: Int) -> UIImage? {
        guard let path = fileFolderImagesURL(pdfName, page: page).path else { fatalError() }
        return UIImage(contentsOfFile: path)
    }
    
    //reads page image from /pdfs/{id}/background_images_small/{page_num}.jpeg
    func getPDFPageImageSmall(_ pdfName: String, page: Int) -> UIImage? {
        guard let path = fileFolderThumbnailImagesURL(pdfName, page: page).path else { fatalError() }
        return UIImage(contentsOfFile: path)
    }
    
    private func imageFromPDFPage(_ page: CGPDFPage, frame: CGRect) -> UIImage {
        // Determine the size of the PDF page.
        var pageRect = page.getBoxRect(CGPDFBox.mediaBox)
        let _PDFScale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height)
        pageRect.size = CGSize(width: pageRect.size.width*_PDFScale, height: pageRect.size.height*_PDFScale)
    
        /*
        Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
        */
        UIGraphicsBeginImageContextWithOptions(pageRect.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
    
        // First fill the background with white.
        context?.setFillColor(red: 1.0,green: 1.0,blue: 1.0,alpha: 1.0)
        context?.fill(pageRect)
    
        context?.saveGState()
        // Flip the context so that the PDF page is rendered right side up.
        context?.translate(x: 0.0, y: pageRect.size.height)
        context?.scale(x: 1.0, y: -1.0)
    
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        context?.scale(x: _PDFScale,y: _PDFScale)
        context?.drawPDFPage(page)
        context?.restoreGState()
    
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return backgroundImage!
    }
    
    //creates images from pdf pages in order to facilitate smooth scrolling
    func preprocessPDF(_ name: String) {
        // create pdf page background images
        guard let pathToPDF = try! self.fileFolderURL(name).appendingPathComponent(name).path else { fatalError() }
        let fileURL = URL(fileURLWithPath: pathToPDF)
        let docURLRef =  fileURL
        
        let thePDFDocRef = CGPDFDocument(docURLRef)
        
        let pageCount = (thePDFDocRef?.numberOfPages)! as Int
        var backgroundImageRect = CGRect.zero
        backgroundImageRect.size = UIScreen.main().bounds.size
        
        for i in 1...pageCount {
            let PDFPage = thePDFDocRef?.page(at: i)
            let backgroundImageData = self.imageFromPDFPage(PDFPage!, frame: backgroundImageRect)
            self.savePDFPageImage(name, pageNumber: i, page: backgroundImageData)
            
            let backgroundImageDataSmall = self.imageFromPDFPage(PDFPage!, frame: CGRect(x: 0, y: 0, width: 240, height: 320))
            self.savePDFPageImageSmall(name, pageNumber: i, page: backgroundImageDataSmall)
        }
    }
}
