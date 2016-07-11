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
    @IBOutlet var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.enabled = false
        
        guard let pdfURL = NSBundle.mainBundle().URLForResource("apple", withExtension: "pdf") else {
            fatalError("File could not be found")
        }
        
        PDFDocument.createPDFDocument(pdfURL, completionHandler: { (success, pdfDocument) -> Void in
            self.pdfDocument = pdfDocument
            self.startButton.enabled = true
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFViewController {
            controller.document = pdfDocument
            controller.title = pdfDocument?.fileName
        }
    }

}
