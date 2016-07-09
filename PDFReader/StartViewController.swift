//
//  StartViewController.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/8/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

internal final class StartViewController: UIViewController {
    var pdfDocument: PDFDocument?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tempPath = NSBundle.mainBundle().pathForResource("mongodb", ofType: "pdf")
        PDFDocument.createPDFDocument("mongodb.pdf", tempPath: tempPath!,completionHandler: { (success, pdfDocument) -> Void in
            self.pdfDocument = pdfDocument
        })
    }
    
    @IBAction private func go() {
        if let pdfDocument = pdfDocument {
            let controller = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewControllerWithIdentifier("PDFViewController") as! PDFViewController
            controller.document = pdfDocument
            presentViewController(controller, animated: true, completion: nil)
        }
    }

}
