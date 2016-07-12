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
    private var currentPDFPage: PDFPageView!
    private var currentPageIndex: Int = 0
    private var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        let numberOfPages = CGFloat(document.pageCount)
        let cellSpacing = CGFloat(2.0)
        let totalSpacing = (numberOfPages - 1.0) * cellSpacing
        let thumbnailWidth = (numberOfPages * PDFThumbnailCell.cellWidth) + totalSpacing
        let width = min(thumbnailWidth, view.bounds.size.width)
        thumbnailCollectionControllerWidth.constant = width
    }
    
    override public func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        let newContentOffsetX = CGFloat(currentPageIndex) * collectionView.bounds.size.width
        collectionView.contentOffset = CGPoint(x: newContentOffsetX, y: collectionView.contentOffset.y)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func print() {
        guard UIPrintInteractionController.isPrintingAvailable() else { return }
        guard UIPrintInteractionController.canPrint(document.fileURL) else { return }
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.duplex = .longEdge
        printInfo.outputType = .general
        printInfo.jobName = document.fileName
        
        let printInteraction = UIPrintInteractionController.shared()
        printInteraction.printInfo = printInfo
        printInteraction.printingItem = document.fileURL
        printInteraction.showsPageRange = true
        printInteraction.present(animated: true, completionHandler: nil)
    }
    
    /// Returns page view
    private func pageView(_ page: Int, cellBounds: CGRect) -> UIScrollView {
        guard let backgroundImage = document.pdfPreprocessor.getPDFPageImage(document.fileName, page: page+1) else { fatalError() }
        guard let pageRef = document.thePDFDocRef.page(at: page + 1) else { fatalError() }
        
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
    
    override public func prefersStatusBarHidden() -> Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override public func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .slide
    }
    
    func handleSingleTap(_ tapRecognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.thumbnailCollectionControllerContainer.isHidden = !self.thumbnailCollectionControllerContainer.isHidden
            self.navigationController?.setNavigationBarHidden(self.navigationController?.isNavigationBarHidden == false, animated: true)
            }) { (completed) in
                let indexPath = IndexPath(row: self.currentPageIndex, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
                self.thumbnailCollectionController?.collectionView?.reloadData()
        }
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PDFThumbnailCollectionViewController {
            thumbnailCollectionController = controller
            controller.document = document
            controller.delegate = self
            controller.currentPageIndex = currentPageIndex
        }
    }
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(_ indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}

extension PDFViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath)
        if let existingView = cell.subviews.flatMap({ $0 as? UIScrollView }).first where existingView.tag == (indexPath as NSIndexPath).row {
            
        } else {
            cell.subviews.forEach({ $0.removeFromSuperview() })
            cell.addSubview(pageView((indexPath as NSIndexPath).row, cellBounds: cell.bounds))
        }
        return cell
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension PDFViewController: UIScrollViewDelegate {
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPageIndex(scrollView)
    }
    
    private func updateCurrentPageIndex(_ scrollView: UIScrollView) {
        let collectionViewContentOffset = max(collectionView.contentOffset.x, 0)
        self.currentPageIndex = Int(floor(collectionViewContentOffset / collectionView.bounds.size.width))
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}
