//
//  StartViewController.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/8/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit
import PDFReader

/// Presents user with some documents which can be viewed
internal final class StartViewController: UIViewController {
    /// Displays a smaller sized PDF document
    @IBAction fileprivate func showSmallPDFDocument() {
        let smallPDFDocumentName = "apple"
        if let doc = document(smallPDFDocumentName) {
            showDocument(doc)
        } else {
            print("Document named \(smallPDFDocumentName) not found in the file system")
        }
    }
    
    /// Displays a larger sized PDF document
    @IBAction fileprivate func showLargePDFDocument() {
        let largePDFDocumentName = "mongodb"
        if let doc = document(largePDFDocumentName) {
            showDocument(doc)
        } else {
            print("Document named \(largePDFDocumentName) not found in the file system")
        }
    }
    
    /// Displays an insanely large sized PDF document
    @IBAction fileprivate func showInsanelyLargePDFDocument() {
        let insanelyLargePDFDocumentName = "javaScript"
        if let doc = document(insanelyLargePDFDocumentName) {
            showDocument(doc)
        } else {
            print("Document named \(insanelyLargePDFDocumentName) not found in the file system")
        }
    }
    
    /// Initializes a document with the name of the pdf in the file system
    ///
    /// - parameter name: name of the pdf in the file system
    ///
    /// - returns: a document
    fileprivate func document(_ name: String) -> PDFDocument? {
        guard let documentURL = Bundle.main.url(forResource: name, withExtension: "pdf") else { return nil }
        return PDFDocument(fileURL: documentURL)
    }
    
    
    /// Presents a document
    ///
    /// - parameter document: document to present
    fileprivate func showDocument(_ document: PDFDocument) {
        let image = UIImage(named: "")
        let controller = PDFViewController.createNew(with: document, title: "", actionButtonImage: image, actionStyle: .activitySheet)
        // controller.scrollDirection = .vertical // use this to scroll from top to bottom instead of left to right
        navigationController?.pushViewController(controller, animated: true)
    }

}
