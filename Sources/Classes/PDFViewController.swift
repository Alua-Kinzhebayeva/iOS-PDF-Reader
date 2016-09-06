//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit


/// Controller that is able to interact and navigate through pages of a `PDFDocument`
public final class PDFViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private weak var thumbnailCollectionControllerContainer: UIView!
    @IBOutlet private var thumbnailCollectionControllerHeight: NSLayoutConstraint!
    @IBOutlet private var thumbnailCollectionControllerWidth: NSLayoutConstraint!
    @IBOutlet private var thumbnailCollectionControllerBottom: NSLayoutConstraint!
    
    /// PDF document that should be displayed
    public var document: PDFDocument!
    
    /// Image used to override the default action button image
    public var actionButtonImage: UIImage?
    
    private var currentPageIndex: Int = 0
    private var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    
    static let images = NSCache()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.registerClass(PDFPageCollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        let actionButton: UIBarButtonItem
        if let actionButtonImage = actionButtonImage {
            actionButton = UIBarButtonItem(image: actionButtonImage, style: .Plain, target: self, action: #selector(print))
        } else {
            actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(print))
        }
        navigationItem.rightBarButtonItem = actionButton
        
        let numberOfPages = CGFloat(document.pageCount)
        let cellSpacing = CGFloat(2.0)
        let totalSpacing = (numberOfPages - 1.0) * cellSpacing
        let thumbnailWidth = (numberOfPages * PDFThumbnailCell.cellWidth) + totalSpacing
        let width = min(thumbnailWidth, view.bounds.size.width)
        thumbnailCollectionControllerWidth.constant = width
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
    
    func print() {
        guard UIPrintInteractionController.isPrintingAvailable() else { return }
        guard UIPrintInteractionController.canPrintURL(document.fileURL) else { return }
        guard document.password == nil else {return }
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
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(indexPath: NSIndexPath) {
        collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Left, animated: false)
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
    private var isThumbnailControllerShown: Bool {
        return thumbnailCollectionControllerBottom.constant == -thumbnailCollectionControllerHeight.constant
    }
    
    private func hideThumbnailController(shouldHide: Bool) {
        if shouldHide {
            self.thumbnailCollectionControllerBottom.constant = -thumbnailCollectionControllerHeight.constant
        } else {
            self.thumbnailCollectionControllerBottom.constant = 0
        }
    }
    
    func handleSingleTap(cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView) {
        let shouldHide = !isThumbnailControllerShown
        UIView.animateWithDuration(0.25, animations: {
            self.hideThumbnailController(shouldHide)
            self.navigationController?.setNavigationBarHidden(shouldHide, animated: true)
        })
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(collectionView.frame.size.width - 1, collectionView.frame.size.height)
    }
}

extension PDFViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let updatedPageIndex = Int(round(max(scrollView.contentOffset.x, 0) / scrollView.bounds.size.width))
        if updatedPageIndex != currentPageIndex {
            currentPageIndex = updatedPageIndex
            thumbnailCollectionController?.currentPageIndex = currentPageIndex
        }
    }
}
