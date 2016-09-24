//
//  StartViewController.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/8/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit
import PDFReader

internal final class StartViewController: UIViewController {
    @IBAction fileprivate func showSmallPDFDocument() {
        let smallPDFDocumentName = "apple"
        showDocument(document(smallPDFDocumentName))
    }
    
    @IBAction fileprivate func showLargePDFDocument() {
        let smallPDFDocumentName = "mongodb"
        showDocument(document(smallPDFDocumentName))
    }
    
    fileprivate func document(_ name: String) -> PDFDocument {
        guard let documentURL = Bundle.main.url(forResource: name, withExtension: "pdf") else {
            fatalError("File could not be found")
        }
        return PDFDocument(fileURL: documentURL)
    }
    
    fileprivate func showDocument(_ document: PDFDocument) {
        let controller = PDFViewController.createNew(with: document)
        navigationController?.pushViewController(controller, animated: true)
    }

}
