//
//  PDFPageView.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/23/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

/// Delegate that is informed of important interaction events with the current `PDFPageView`
protocol PDFPageViewDelegate: class {
    /// User has tapped on the page view
    func handleSingleTap(_ pdfPageView: PDFPageView)
}

/// An interactable page of a document
internal final class PDFPageView: UIScrollView {
    /// The TiledPDFView that is currently front most.
    private var tiledPDFView: TiledView
    
    /// Current scale of the scrolling view
    private var scale: CGFloat
    
    /// Number of zoom levels possible when double tapping
    private let zoomLevels: CGFloat = 2
    
    /// View which contains all of our content
    private var contentView: UIView
    
    /// A low resolution image of the PDF page that is displayed until the TiledPDFView renders its content.
    private let backgroundImageView: UIImageView
    
    /// Page reference being displayed
    private let pdfPage: CGPDFPage
    
    /// Current amount being zoomed
    private var zoomAmount: CGFloat?
    
    /// Delegate that is informed of important interaction events
    private weak var pageViewDelegate: PDFPageViewDelegate?
    
    /// Instantiates a scrollable page view
    ///
    /// - parameter frame:            frame of the view
    /// - parameter document:         document to be displayed
    /// - parameter pageNumber:       specific page number of the document to display
    /// - parameter backgroundImage:  background image of the page to display while rendering
    /// - parameter pageViewDelegate: delegate notified of any important interaction events
    ///
    /// - returns: a freshly initialized page view
    init(frame: CGRect, document: PDFDocument, pageNumber: Int, backgroundImage: UIImage?, pageViewDelegate: PDFPageViewDelegate?) {
        guard let pageRef = document.coreDocument.page(at: pageNumber + 1) else { fatalError() }
        
        pdfPage = pageRef
        self.pageViewDelegate = pageViewDelegate
        
        let originalPageRect = pageRef.originalPageRect
        
        scale = min(frame.width/originalPageRect.width, frame.height/originalPageRect.height)
        let scaledPageRectSize = CGSize(width: originalPageRect.width * scale, height: originalPageRect.height * scale)
        let scaledPageRect = CGRect(origin: originalPageRect.origin, size: scaledPageRectSize)
        
        guard !scaledPageRect.isEmpty else { fatalError() }
        
        // Create our content view based on the size of the PDF page
        contentView = UIView(frame: scaledPageRect)
        
        backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.frame = contentView.bounds
        
        // Create the TiledPDFView and scale it to fit the content view.
        tiledPDFView = TiledView(frame: contentView.bounds, scale: scale, newPage: pdfPage)
        
        super.init(frame: frame)
        
        let targetRect = bounds.insetBy(dx: 0, dy: 0)
        var zoomScale = zoomScaleThatFits(targetRect.size, source: bounds.size)
        
        minimumZoomScale = zoomScale // Set the minimum and maximum zoom scales
        maximumZoomScale = zoomScale * (zoomLevels * zoomLevels) // Max number of zoom levels
        zoomAmount = (maximumZoomScale - minimumZoomScale) / zoomLevels
        
        scale = 1
        if zoomScale > minimumZoomScale {
            zoomScale = minimumZoomScale
        }
        
        contentView.addSubview(backgroundImageView)
        contentView.sendSubviewToBack(backgroundImageView)
        contentView.addSubview(tiledPDFView)
        addSubview(contentView)
        
        let doubleTapOne = UITapGestureRecognizer(target: self, action:#selector(handleDoubleTap))
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.cancelsTouchesInView = false
        addGestureRecognizer(doubleTapOne)
        
        let singleTapOne = UITapGestureRecognizer(target: self, action:#selector(handleSingleTap))
        singleTapOne.numberOfTapsRequired = 1
        singleTapOne.cancelsTouchesInView = false
        addGestureRecognizer(singleTapOne)
        
        singleTapOne.require(toFail: doubleTapOne)
        
        bouncesZoom = false
        decelerationRate = UIScrollView.DecelerationRate.fast
        delegate = self
        autoresizesSubviews = true
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use layoutSubviews to center the PDF page in the view.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Center the image as it becomes smaller than the size of the screen.
        let contentViewSize = contentView.frame.size
    
        // Center horizontally.
        let xOffset: CGFloat
        if contentViewSize.width < bounds.width {
            xOffset = (bounds.width - contentViewSize.width) / 2
        } else {
            xOffset = 0
        }
    
        // Center vertically.
        let yOffset: CGFloat
        if contentViewSize.height < bounds.height {
            yOffset = (bounds.height - contentViewSize.height) / 2
        } else {
            yOffset = 0
        }
        
        contentView.frame = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: contentViewSize)
    
        // To handle the interaction between CATiledLayer and high resolution screens, set the 
        // tiling view's contentScaleFactor to 1.0. If this step were omitted, the content scale factor 
        // would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
        tiledPDFView.contentScaleFactor = 1
    }
    
    /// Notifies the delegate that a single tap was performed
    @objc func handleSingleTap(_ tapRecognizer: UITapGestureRecognizer) {
        pageViewDelegate?.handleSingleTap(self)
    }
    
    /// Zooms in and out accordingly, based on the current zoom level
    @objc func handleDoubleTap(_ tapRecognizer: UITapGestureRecognizer) {
        var newScale = zoomScale * zoomLevels
        if newScale >= maximumZoomScale {
            newScale = minimumZoomScale
        }
        let zoomRect = zoomRectForScale(newScale, zoomPoint: tapRecognizer.location(in: tapRecognizer.view))
        zoom(to: zoomRect, animated: true)
    }
    
    
    /// Calculates the zoom scale given a target size and a source size
    ///
    /// - parameter target: size of the target rect
    /// - parameter source: size of the source rect
    ///
    /// - returns: the zoom scale of the target in relation to the source
    private func zoomScaleThatFits(_ target: CGSize, source: CGSize) -> CGFloat {
        let widthScale = target.width / source.width
        let heightScale = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
    /// Calculates the new zoom rect given a desired scale and a point to zoom on
    ///
    /// - parameter scale:     desired scale to zoom to
    /// - parameter zoomPoint: the reference point to zoom on
    ///
    /// - returns: a new zoom rect
    private func zoomRectForScale(_ scale: CGFloat, zoomPoint: CGPoint) -> CGRect {
        // Normalize current content size back to content scale of 1.0f
        let updatedContentSize = CGSize(width: contentSize.width/zoomScale, height: contentSize.height/zoomScale)
    
        let translatedZoomPoint = CGPoint(x: (zoomPoint.x / bounds.width) * updatedContentSize.width,
                                          y: (zoomPoint.y / bounds.height) * updatedContentSize.height)
    
        // derive the size of the region to zoom to
        let zoomSize = CGSize(width: bounds.width / scale, height: bounds.height / scale)
    
        // offset the zoom rect so the actual zoom point is in the middle of the rectangle
        return CGRect(x: translatedZoomPoint.x - zoomSize.width / 2.0,
                      y: translatedZoomPoint.y - zoomSize.height / 2.0,
                      width: zoomSize.width,
                      height: zoomSize.height)
    }
}

extension PDFPageView: UIScrollViewDelegate {
    /// A UIScrollView delegate callback, called when the user starts zooming.
    /// Return the content view
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    /// A UIScrollView delegate callback, called when the user stops zooming.
    /// When the user stops zooming, create a new Tiled
    /// PDFView based on the new zoom level and draw it on top of the old TiledPDFView.
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.scale = scale
    }
}
