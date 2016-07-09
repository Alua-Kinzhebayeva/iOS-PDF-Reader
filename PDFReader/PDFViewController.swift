//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

internal final class PDFViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    
    var document: PDFDocument!
    private var currentPDFPage: PDFPageView!
    private var currentPageIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        view.backgroundColor = UIColor.clearColor()
        collectionView.backgroundColor = UIColor.clearColor()
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let newContentOffsetX = CGFloat(currentPageIndex) * collectionView.bounds.size.width
        collectionView.contentOffset = CGPointMake(newContentOffsetX, collectionView.contentOffset.y)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    /// Returns page view
    private func pageView(page: Int, cell: UICollectionViewCell) -> UIScrollView {
        let pageTuple = document.getPage(page)
        guard let pageRef = pageTuple.pageRef else { fatalError() }
        guard let backgroundImage = pageTuple.backgroundImage else { fatalError() }
        let scrollView = PDFPageView(frame: cell.bounds, PDFPageRef: pageRef, backgroundImage: backgroundImage)
        
        currentPDFPage = scrollView
        let doubleTapOne = UITapGestureRecognizer(target: scrollView, action:#selector(PDFPageView.handleDoubleTap(_:)))
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(doubleTapOne)
        return scrollView
    }
}

extension PDFViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount.integerValue
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("page", forIndexPath: indexPath)
        cell.subviews.forEach({ $0.removeFromSuperview() })
        cell.addSubview(pageView(indexPath.row, cell: cell))
        return cell
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.height-20)
    }
}

extension PDFViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.currentPageIndex =  Int(floor(collectionView.contentOffset.x / collectionView.bounds.size.width))
    }
}
