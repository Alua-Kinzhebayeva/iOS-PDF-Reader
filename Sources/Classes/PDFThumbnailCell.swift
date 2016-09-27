//
//  PDFThumbnailCell.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/9/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

/// An individual thumbnail in the collection view
internal final class PDFThumbnailCell: UICollectionViewCell {
    /// Preferred size of each cell
    static let cellSize = CGSize(width: 24, height: 44)
    
    @IBOutlet var imageView: UIImageView?
}
