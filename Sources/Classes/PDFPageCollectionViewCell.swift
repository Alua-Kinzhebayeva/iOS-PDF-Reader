//
//  PDFPageCollectionViewCell.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/12/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

/// Delegate that is informed of important interaction events with the pdf page collection view
protocol PDFPageCollectionViewCellDelegate: class {
    func handleSingleTap(_ cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView)
}

/// A cell housing the interactable pdf page view
internal final class PDFPageCollectionViewCell: UICollectionViewCell {
    /// Index of the page
    var pageIndex: Int?
    
    /// Page view of the current page in the document
    var pageView: PDFPageView? {
        didSet {
            subviews.forEach{ $0.removeFromSuperview() }
            if let pageView = pageView {
                addSubview(pageView)
            }
        }
    }
    
    /// Delegate informed of important events
    private weak var pageCollectionViewCellDelegate: PDFPageCollectionViewCellDelegate?
    
    
    /// Customizes and sets up the cell to be ready to be displayed
    ///
    /// - parameter indexPathRow:                   page index of the document to be displayed
    /// - parameter collectionViewBounds:           bounds of the entire collection view
    /// - parameter document:                       document to be displayed
    /// - parameter pageCollectionViewCellDelegate: delegate informed of important events
    func setup(_ indexPathRow: Int, collectionViewBounds: CGRect, document: PDFDocument, pageCollectionViewCellDelegate: PDFPageCollectionViewCellDelegate?) {
        self.pageCollectionViewCellDelegate = pageCollectionViewCellDelegate
        document.pdfPageImage(at: indexPathRow + 1) { (backgroundImage) in
            pageView = PDFPageView(frame: bounds, document: document, pageNumber: indexPathRow, backgroundImage: backgroundImage, pageViewDelegate: self)
            pageIndex = indexPathRow
        }
    }
}

extension PDFPageCollectionViewCell: PDFPageViewDelegate {
    func handleSingleTap(_ pdfPageView: PDFPageView) {
        pageCollectionViewCellDelegate?.handleSingleTap(self, pdfPageView: pdfPageView)
    }
}
