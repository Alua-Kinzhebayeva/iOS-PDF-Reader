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
        startButton.isEnabled = false
        
        guard let pdfURL = Bundle.main.urlForResource("mongodb", withExtension: "pdf") else {
            fatalError("File could not be found")
        }
        
        let priority = DispatchQueue.GlobalAttributes.qosDefault
        DispatchQueue.global(attributes: priority).async {
            self.pdfDocument = PDFDocument(tempURL: pdfURL)
            DispatchQueue.main.async {
                // update some UI
                self.startButton.isEnabled = true
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFViewController {
            controller.document = pdfDocument
            controller.title = pdfDocument?.fileName
        }
    }

}
