//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

public final class PDFViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private weak var thumbnailCollectionControllerContainer: UIView!
    @IBOutlet private var thumbnailCollectionControllerWidth: NSLayoutConstraint!
    
    public var document: PDFDocument!
    private var currentPageIndex: Int = 0
    private var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(PDFPageCollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        let numberOfPages = CGFloat(document.pageCount)
        let cellSpacing = CGFloat(2.0)
        let totalSpacing = (numberOfPages - 1.0) * cellSpacing
        let thumbnailWidth = (numberOfPages * PDFThumbnailCell.cellWidth) + totalSpacing
        let width = min(thumbnailWidth, view.bounds.size.width)
        thumbnailCollectionControllerWidth.constant = width
    }
    
    @IBAction func print() {
        guard UIPrintInteractionController.isPrintingAvailable() else { return }
        guard UIPrintInteractionController.canPrintURL(document.fileURL) else { return }
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.duplex = .LongEdge
        printInfo.outputType = .General
        printInfo.jobName = document.fileName
        
        let printInteraction = UIPrintInteractionController.sharedPrintController()
        printInteraction.printInfo = printInfo
        printInteraction.printingItem = document.fileURL
        printInteraction.showsPageRange = true
        printInteraction.presentAnimated(true, completionHandler: nil)
    }
    
    override public func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override public func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFThumbnailCollectionViewController {
            thumbnailCollectionController = controller
            controller.document = document
            controller.delegate = self
            controller.currentPageIndex = currentPageIndex
        }
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) in
            let currentIndexPath = NSIndexPath(forRow: self.currentPageIndex, inSection: 0)
            self.collectionView.reloadItemsAtIndexPaths([currentIndexPath])
            self.collectionView.scrollToItemAtIndexPath(currentIndexPath, atScrollPosition: .CenteredHorizontally, animated: false)
            }) { (context) in
                self.thumbnailCollectionController?.currentPageIndex = self.currentPageIndex
        }
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(indexPath: NSIndexPath) {
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}

extension PDFViewController: UICollectionViewDataSource {
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("page", forIndexPath: indexPath) as! PDFPageCollectionViewCell
        cell.setup(indexPath.row, collectionViewBounds: collectionView.bounds, document: document, pageCollectionViewCellDelegate: self)
        return cell
    }
}

extension PDFViewController: PDFPageCollectionViewCellDelegate {
    func handleSingleTap(cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView) {
        UIView.animateWithDuration(0.3, animations: {
            self.thumbnailCollectionControllerContainer.hidden = !self.thumbnailCollectionControllerContainer.hidden
            self.navigationController?.setNavigationBarHidden(self.navigationController?.navigationBarHidden == false, animated: true)
        })
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension PDFViewController: UIScrollViewDelegate {
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    private func updateCurrentPageIndex(scrollView: UIScrollView) {
        let collectionViewContentOffset = max(scrollView.contentOffset.x, 0)
        self.currentPageIndex = Int(floor(collectionViewContentOffset / scrollView.bounds.size.width))
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}
