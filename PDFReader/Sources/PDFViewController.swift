//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

internal final class PDFViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet weak var thumbnailCollectionControllerContainer: UIView!
    
    var document: PDFDocument!
    private var currentPDFPage: PDFPageView!
    private var currentPageIndex: Int = 0
    private var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "page")
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let newContentOffsetX = CGFloat(currentPageIndex) * collectionView.bounds.size.width
        collectionView.contentOffset = CGPointMake(newContentOffsetX, collectionView.contentOffset.y)
        collectionView.collectionViewLayout.invalidateLayout()
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
    
    /// Returns page view
    private func pageView(page: Int, cellBounds: CGRect) -> UIScrollView {
        let pageTuple = document.getPage(page)
        guard let pageRef = pageTuple.pageRef else { fatalError() }
        guard let backgroundImage = pageTuple.backgroundImage else { fatalError() }
        let scrollView = PDFPageView(frame: cellBounds, PDFPageRef: pageRef, backgroundImage: backgroundImage)
        scrollView.tag = page
        
        currentPDFPage = scrollView
        let doubleTapOne = UITapGestureRecognizer(target: scrollView, action:#selector(PDFPageView.handleDoubleTap(_:)))
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(doubleTapOne)
        
        let singleTapOne = UITapGestureRecognizer(target: self, action:#selector(PDFViewController.handleSingleTap(_:)))
        singleTapOne.numberOfTapsRequired = 1
        singleTapOne.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(singleTapOne)
        
        return scrollView
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    func handleSingleTap(tapRecognizer: UITapGestureRecognizer) {
        UIView.animateWithDuration(0.3, animations: { 
            self.thumbnailCollectionControllerContainer.hidden = !self.thumbnailCollectionControllerContainer.hidden
            self.navigationController?.setNavigationBarHidden(self.navigationController?.navigationBarHidden == false, animated: true)
            }) { (completed) in
                let indexPath = NSIndexPath(forRow: self.currentPageIndex, inSection: 0)
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
                self.thumbnailCollectionController?.collectionView?.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFThumbnailCollectionViewController {
            thumbnailCollectionController = controller
            controller.document = document
            controller.delegate = self
            controller.currentPageIndex = currentPageIndex
        }
    }
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(indexPath: NSIndexPath) {
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: true)
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}

extension PDFViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount.integerValue
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("page", forIndexPath: indexPath)
        if let existingView = cell.subviews.flatMap({ $0 as? UIScrollView }).first where existingView.tag == indexPath.row {
            
        } else {
            cell.subviews.forEach({ $0.removeFromSuperview() })
            cell.addSubview(pageView(indexPath.row, cellBounds: cell.bounds))
        }
        return cell
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension PDFViewController: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    private func updateCurrentPageIndex(scrollView: UIScrollView) {
        self.currentPageIndex = Int(floor(collectionView.contentOffset.x / collectionView.bounds.size.width))
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}
