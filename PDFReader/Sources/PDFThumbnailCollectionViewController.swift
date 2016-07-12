//
//  PDFThumbnailCollectionViewController.swift
//  PDFReader
//
//  Created by Ricardo Nunez on 7/9/16.
//  Copyright © 2016 AK. All rights reserved.
//

import UIKit

protocol PDFThumbnailControllerDelegate: class {
    func didSelectIndexPath(_ indexPath: IndexPath)
}

internal final class PDFThumbnailCollectionViewController: UICollectionViewController {
    var document: PDFDocument!
    
    var currentPageIndex: Int = 0 {
        didSet {
            guard let collectionView = collectionView else { return }
            let curentPageIndexPath = IndexPath(row: currentPageIndex, section: 0)
            if !collectionView.indexPathsForVisibleItems().contains(curentPageIndexPath) {
                collectionView.scrollToItem(at: curentPageIndexPath, at: .centeredHorizontally, animated: true)
            }
            collectionView.reloadData()
        }
    }
    
    weak var delegate: PDFThumbnailControllerDelegate?
    
    private var pageImages: [UIImage]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageImages = document.allPageImages()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageImages?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PDFThumbnailCell
        
        cell.imageView?.image = pageImages[(indexPath as NSIndexPath).row]
        if currentPageIndex == (indexPath as NSIndexPath).row {
            cell.alpha = 1.0
        } else {
            cell.alpha = 0.2
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: PDFThumbnailCell.cellWidth, height: PDFThumbnailCell.cellHeight)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectIndexPath(indexPath)
    }
}
