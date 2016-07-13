//
//  PDFPageCollectionViewCell.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/12/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

protocol PDFPageCollectionViewCellDelegate: class {
    func handleSingleTap(cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView)
}

internal final class PDFPageCollectionViewCell: UICollectionViewCell {
    var pageIndex: Int?
    var pageView: PDFPageView? {
        didSet {
            subviews.forEach({ $0.removeFromSuperview() })
            if let pageView = pageView {
                addSubview(pageView)
            }
            
        }
    }
    
    private weak var pageCollectionViewCellDelegate: PDFPageCollectionViewCellDelegate?
    
    func setup(indexPathRow: Int, collectionViewBounds: CGRect, document: PDFDocument, pageCollectionViewCellDelegate: PDFPageCollectionViewCellDelegate?) {
        guard let backgroundImage = document.pdfPreprocessor.getPDFPageImage(document.fileName, page: indexPathRow + 1) else { fatalError() }
        guard let pageRef = CGPDFDocumentGetPage(document.thePDFDocRef, indexPathRow + 1) else { fatalError() }
        
        self.pageCollectionViewCellDelegate = pageCollectionViewCellDelegate
        pageView = PDFPageView(frame: bounds, PDFPageRef: pageRef, backgroundImage: backgroundImage, pageViewDelegate: self)
        pageIndex = indexPathRow
    }
}

extension PDFPageCollectionViewCell: PDFPageViewDelegate {
    func handleSingleTap(pdfPageView: PDFPageView) {
        pageCollectionViewCellDelegate?.handleSingleTap(self, pdfPageView: pdfPageView)
    }
}
