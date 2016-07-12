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
        
        guard let pdfURL = NSBundle.mainBundle().URLForResource("mongodb", withExtension: "pdf") else {
            fatalError("File could not be found")
        }
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.pdfDocument = PDFDocument(tempURL: pdfURL)
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
                self.startButton.enabled = true
            }
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFViewController {
            controller.document = pdfDocument
            controller.title = pdfDocument?.fileName
        }
    }

}
