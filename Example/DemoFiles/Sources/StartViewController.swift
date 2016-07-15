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
    @IBAction private func showSmallPDFDocument() {
        let smallPDFDocumentName = "apple"
        showDocument(document(smallPDFDocumentName))
    }
    
    @IBAction private func showLargePDFDocument() {
        let smallPDFDocumentName = "mongodb"
        showDocument(document(smallPDFDocumentName))
    }
    
    private func document(name: String) -> PDFDocument {
        guard let documentURL = NSBundle.mainBundle().URLForResource(name, withExtension: "pdf") else {
            fatalError("File could not be found")
        }
        return PDFDocument(tempURL: documentURL)
    }
    
    private func showDocument(document: PDFDocument) {
        let storyboard = UIStoryboard(name: "PDFReader", bundle: NSBundle(forClass: PDFViewController.self))
        let controller = storyboard.instantiateInitialViewController() as! PDFViewController
        controller.document = document
        controller.title = document.fileName
        navigationController?.pushViewController(controller, animated: true)
    }

}
