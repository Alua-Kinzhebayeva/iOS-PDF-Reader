//
//  PDFPageCollectionViewCell.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/12/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

internal final class PDFPageCollectionViewCell: UICollectionViewCell {
    var pageView: UIScrollView? {
        didSet {
            subviews.forEach({ $0.removeFromSuperview() })
            if let pageView = pageView {
                addSubview(pageView)
            }
            
        }
    }
    
    var pageIndex: Int?
}
