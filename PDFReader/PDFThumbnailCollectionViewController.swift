//
//  PDFThumbnailCollectionViewController.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/9/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

protocol PDFThumbnailControllerDelegate: class {
    func didSelectIndexPath(indexPath: NSIndexPath)
}

internal final class PDFThumbnailCollectionViewController: UICollectionViewController {
    var document: PDFDocument!
    weak var delegate: PDFThumbnailControllerDelegate?
    
    private var pageImages: [UIImage]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageImages = document.allPageImages()
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageImages?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! PDFThumbnailCell
        cell.imageView?.image = pageImages[indexPath.row]
        return cell
    }
    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.didSelectIndexPath(indexPath)
    }
}
