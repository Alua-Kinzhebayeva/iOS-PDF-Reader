//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

extension PDFViewController {
    /// Initializes a new `PDFViewController`
    ///
    /// - parameter document:            PDF document to be displayed
    /// - parameter title:               title that displays on the navigation bar on the PDFViewController; 
    ///                                  if nil, uses document's filename
    /// - parameter actionButtonImage:   image of the action button; if nil, uses the default action system item image
    /// - parameter actionStyle:         sytle of the action button
    /// - parameter backButton:          button to override the default controller back button
    /// - parameter isThumbnailsEnabled: whether or not the thumbnails bar should be enabled
    /// - parameter startPageIndex:      page index to start on load, defaults to 0; if out of bounds, set to 0
    ///
    /// - returns: a `PDFViewController`
//    public class func createNew(with document: PDFDocument, title: String? = nil, actionButtonImage: UIImage? = nil, actionStyle: ActionStyle?, isThumbnailsEnabled: Bool = true, startPageIndex: Int = 0) -> PDFViewController {
//        let storyboard = UIStoryboard(name: "PDFReader", bundle: Bundle(for: PDFViewController.self))
//        let controller = storyboard.instantiateInitialViewController() as! PDFViewController
//        controller.document = document
//        controller.actionStyle = actionStyle
//        
//        if let title = title {
//            controller.title = title
//        } else {
//            controller.title = document.fileName
//        }
//        
//        if startPageIndex >= 0 && startPageIndex < document.pageCount {
//            controller.currentPageIndex = startPageIndex
//        } else {
//            controller.currentPageIndex = 0
//        }
//
////        controller.backButtonImage = backButtonImage
//        
//        if actionStyle != nil {
//            if let actionButtonImage = actionButtonImage {
//                controller.actionButton = UIBarButtonItem(image: actionButtonImage, style: .plain, target: controller, action: #selector(actionButtonPressed))
//            } else {
//                controller.actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: controller, action: #selector(actionButtonPressed))
//            }
//        } else {
//            controller.actionButton = nil
//        }
//        controller.isThumbnailsEnabled = isThumbnailsEnabled
//        return controller
//    }
    
    public class func createNew(with document: PDFDocument, properties: PDFViewUIProperties) -> PDFViewController {
        let storyboard = UIStoryboard(name: "PDFReader", bundle: Bundle(for: PDFViewController.self))
        let controller = storyboard.instantiateInitialViewController() as! PDFViewController
        controller.document = document
        controller.uiProperties = properties
        
        return controller
    }
}

/// Controller that is able to interact and navigate through pages of a `PDFDocument`
public final class PDFViewController: UIViewController {
    /// Action button style
    public enum ActionStyle {
        /// Brings up a print modal allowing user to print current PDF
        case print
        
        /// Brings up an activity sheet to share or open PDF in another app
        case activitySheet
        
        /// Performs a custom action
        case customAction(() -> ())
    }
    
    /// View representing the navigation bar
    @IBOutlet public var navigationView: UIView!
    
    /// button for returning to previous view
    @IBOutlet public var backButton: UIButton!
    
    /// Label for title
    @IBOutlet public var titleLabel: UILabel!
    
    /// Label for subtitle
    @IBOutlet public var subtitleLabel: UILabel!
    
    /// Line view in the navigation view
    @IBOutlet public var lineView: UIView!
    
    /// Line view above the thumbnails
    @IBOutlet public var lineViewSeparatingThumbnails: UIView!
    
    /// Collection veiw where all the pdf pages are rendered
    @IBOutlet public var collectionView: UICollectionView!
    
    /// Height of the navigation view (used to hide/show)
    @IBOutlet private var navigationViewHeight: NSLayoutConstraint!
    
    /// Distance between the top of navigation view with top of page (used to hide/show)
    @IBOutlet private var navigationViewTop: NSLayoutConstraint!
    
    /// Height of the thumbnail bar (used to hide/show)
    @IBOutlet private var thumbnailCollectionControllerHeight: NSLayoutConstraint!
    
    /// Distance between the bottom thumbnail bar with bottom of page (used to hide/show)
    @IBOutlet private var thumbnailCollectionControllerBottom: NSLayoutConstraint!
    
    /// Width of the thumbnail bar (used to resize on rotation events)
    @IBOutlet private var thumbnailCollectionControllerWidth: NSLayoutConstraint!
    
    /// PDF document that should be displayed
    private var document: PDFDocument!
    
    private var actionStyle: ActionStyle?
    
    /// Image used to override the default action button image
    private var actionButtonImage: UIImage?
    
    /// Current page being displayed
    private var currentPageIndex: Int = 0
    
    /// Bottom thumbnail controller
    private var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    
    /// UIBarButtonItem used to override the default action button
    private var actionButton: UIBarButtonItem?
    
    /// Background color to apply to the collectionView.
    public var backgroundColor: UIColor? = .lightGray /*{
        didSet {
            collectionView?.backgroundColor = backgroundColor
        }
    }*/
    
//    ///Back button image
//    private var backButtonImage: UIImage?
    
    /// Whether or not the thumbnails bar should be enabled
    private var isThumbnailsEnabled = true {
        didSet {
            if thumbnailCollectionControllerHeight == nil {
                _ = view
            }
            if !isThumbnailsEnabled {
                thumbnailCollectionControllerHeight.constant = 0
            }
        }
    }
    
    /// Slides horizontally (from left to right, default) or vertically (from top to bottom)
    public var scrollDirection: UICollectionViewScrollDirection = .horizontal {
        didSet {
            if collectionView == nil {  // if the user of the controller is trying to change the scrollDiecton before it
                _ = view                // is on the sceen, we need to show it ofscreen to access it's collectionView.
            }
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.scrollDirection = scrollDirection
            }
        }
    }
    
    /// UI values
    private var uiProperties: PDFViewUIProperties?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red//backgroundColor//.lightGray
        collectionView.backgroundColor = .cyan//.clear//backgroundColor
        collectionView.register(PDFPageCollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        navigationItem.rightBarButtonItem = actionButton

        navigationItem.hidesBackButton = true
        
        let numberOfPages = CGFloat(document.pageCount)
        let cellSpacing = CGFloat(2.0)
        let totalSpacing = (numberOfPages - 1.0) * cellSpacing
        let thumbnailWidth = (numberOfPages * PDFThumbnailCell.cellSize.width) + totalSpacing
        let width = min(thumbnailWidth, view.bounds.width)
        thumbnailCollectionControllerWidth.constant = width
        
        lineViewSeparatingThumbnails.backgroundColor = backgroundColor
        
        if let properties = uiProperties {
            if let title = properties.title {
                titleLabel.text = title
                if let font = properties.titleFont {
                    titleLabel.font = font
                }
            } else {
                titleLabel.text = ""
            }
            if let subtitle = properties.subtitle {
                subtitleLabel.text = subtitle
                if let font = properties.subtitleFont {
                    subtitleLabel.font = font
                }
            } else {
                subtitleLabel.text = ""
            }
            
            backButton.setImage(properties.backButtonImage, for: .normal)
            backButton.setTitle((properties.backButtonImage != nil ? "" : "Back"), for: .normal)
            
            isThumbnailsEnabled = properties.isThumbnailsEnabled
            
            if let lineViewColor = properties.lineViewColor {
                lineView.backgroundColor = lineViewColor
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        didSelectIndexPath(IndexPath(row: currentPageIndex, section: 0))
    }
    
    override public var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    public override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return isThumbnailsEnabled
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PDFThumbnailCollectionViewController {
            thumbnailCollectionController = controller
            controller.document = document
            controller.delegate = self
            controller.currentPageIndex = currentPageIndex
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            let currentIndexPath = IndexPath(row: self.currentPageIndex, section: 0)
            self.collectionView.reloadItems(at: [currentIndexPath])
            self.collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: false)
            }) { context in
                self.thumbnailCollectionController?.currentPageIndex = self.currentPageIndex
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    ///Back button tapped
    @IBAction func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    /// Takes an appropriate action based on the current action style
    @objc func actionButtonPressed() {
        if let actionStyle = actionStyle {
            switch actionStyle {
            case .print:
                print()
            case .activitySheet:
                presentActivitySheet()
            case .customAction(let customAction):
                customAction()
            }
        }
    }
    
    /// Presents activity sheet to share or open PDF in another app
    private func presentActivitySheet() {
        let controller = UIActivityViewController(activityItems: [document.fileData], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = actionButton
        present(controller, animated: true, completion: nil)
    }
    
    /// Presents print sheet to print PDF
    private func print() {
        guard UIPrintInteractionController.isPrintingAvailable else { return }
        guard UIPrintInteractionController.canPrint(document.fileData) else { return }
        guard document.password == nil else { return }
        let printInfo = UIPrintInfo.printInfo()
        printInfo.duplex = .longEdge
        printInfo.outputType = .general
        printInfo.jobName = document.fileName
        
        let printInteraction = UIPrintInteractionController.shared
        printInteraction.printInfo = printInfo
        printInteraction.printingItem = document.fileData
        printInteraction.showsPageRange = true
        printInteraction.present(animated: true, completionHandler: nil)
    }
}

extension PDFViewController: PDFThumbnailControllerDelegate {
    func didSelectIndexPath(_ indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        thumbnailCollectionController?.currentPageIndex = currentPageIndex
    }
}

extension PDFViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return document.pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath) as! PDFPageCollectionViewCell
        
        cell.setup(indexPath.row, collectionViewBounds: collectionView.bounds, document: document, pageCollectionViewCellDelegate: self)
        return cell
    }
}

extension PDFViewController: PDFPageCollectionViewCellDelegate {
    /// Toggles the hiding/showing of the thumbnail controller
    ///
    /// - parameter shouldHide: whether or not the controller should hide the thumbnail controller
//    private func hideThumbnailController(_ shouldHide: Bool) {
//        self.thumbnailCollectionControllerBottom.constant = shouldHide ? -thumbnailCollectionControllerHeight.constant : 0
//    }
    
    func handleSingleTap(_ cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView) {
        if navigationViewTop.constant < CGFloat(0.0) {
            navigationViewTop.constant = CGFloat(0.0)
            thumbnailCollectionControllerBottom.constant = CGFloat(0.0)
        } else {
            navigationViewTop.constant = -navigationViewHeight.constant
            thumbnailCollectionControllerBottom.constant = -thumbnailCollectionControllerHeight.constant
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

extension PDFViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

extension PDFViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let updatedPageIndex: Int
        if self.scrollDirection == .vertical {
            updatedPageIndex = Int(round(max(scrollView.contentOffset.y, 0) / scrollView.bounds.height))
        } else {
            updatedPageIndex = Int(round(max(scrollView.contentOffset.x, 0) / scrollView.bounds.width))
        }
        
        if updatedPageIndex != currentPageIndex {
            currentPageIndex = updatedPageIndex
            thumbnailCollectionController?.currentPageIndex = currentPageIndex
        }
    }
}
