//
//  PDFThumbnailCell.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/9/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

internal final class PDFThumbnailCell: UICollectionViewCell {
    static let cellWidth: CGFloat = 30
    static let cellHeight: CGFloat = 56
    
    @IBOutlet var imageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
