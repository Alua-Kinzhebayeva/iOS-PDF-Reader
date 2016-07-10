//
//  PDFPageView.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/23/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import Foundation
import UIKit

internal final class PDFPageView: UIScrollView {
    private let ZOOM_LEVELS = 2
    private let ZOOM_STEP = 2
    private let CONTENT_INSET: CGFloat = 2
    
    /// A low resolution image of the PDF page that is displayed until the TiledPDFView renders its content.
    private let backgroundImageView: UIImageView
    
    private let PDFPage: CGPDFPageRef
    
    /// The TiledPDFView that is currently front most.
    private var tiledPDFView: TiledView!
    
    private var PDFScale: CGFloat?
    private var customFrame: CGRect?
    private var zoomAmount: CGFloat?
    private var isAtMaximumZoom: Bool = false
    
    init(frame: CGRect, PDFPageRef: CGPDFPageRef, backgroundImage: UIImage) {
        PDFPage = PDFPageRef
        
        // Determine the size of the PDF page.
        var pageRect = CGPDFPageGetBoxRect(PDFPage, CGPDFBox.MediaBox)
        
        PDFScale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height)
        pageRect.size = CGSizeMake(pageRect.size.width * PDFScale!, pageRect.size.height * PDFScale!)
        
        guard !CGRectIsEmpty(pageRect) else { fatalError() }
        
        backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.frame = pageRect
        customFrame = pageRect
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
        tiledPDFView = TiledView(frame: pageRect, scale: PDFScale!, newPage: PDFPage)
        
        super.init(frame: frame)
        
        updateMinimumMaximumZoom()
        zoomReset()
        
        addSubview(backgroundImageView)
        sendSubviewToBack(backgroundImageView)
        addSubview(tiledPDFView)
        
        bouncesZoom = false
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        autoresizesSubviews = true
        autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if customFrame?.width != frame.width {
            customFrame = frame
            var pageRect = CGPDFPageGetBoxRect(PDFPage, CGPDFBox.MediaBox)
            PDFScale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height)
            pageRect.size = CGSizeMake(pageRect.size.width * PDFScale!, pageRect.size.height * PDFScale!)
            let newTiledView = TiledView(frame: pageRect, scale: PDFScale!, newPage: PDFPage)
            addSubview(newTiledView)
            tiledPDFView.removeFromSuperview()
            tiledPDFView = newTiledView
            contentSize = tiledPDFView.bounds.size
        }
    }
    
    // Use layoutSubviews to center the PDF page in the view.
    override func layoutSubviews() {
        super.layoutSubviews()
    
        // Center the image as it becomes smaller than the size of the screen.
    
        let boundsSize = bounds.size
        var frameToCenter = tiledPDFView.frame
    
        // Center horizontally.
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
    
        // Center vertically.
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
    
        tiledPDFView.frame = frameToCenter
        backgroundImageView.frame = frameToCenter
    
        /*
        To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
        If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
        */
        tiledPDFView.contentScaleFactor = 1.0
    }
    
    func handleDoubleTap(tapRecognizer: UITapGestureRecognizer) {
        var newScale = zoomScale * CGFloat(ZOOM_STEP)
        if newScale >= maximumZoomScale {
            newScale = minimumZoomScale
        }
        backgroundImageView.hidden = true
        let zoomRect = zoomRectForScale(newScale, zoomPoint: tapRecognizer.locationInView(tapRecognizer.view))
        zoomToRect(zoomRect, animated: true)
        backgroundImageView.hidden = false
    }
    
    private func ZoomScaleThatFits(target: CGSize, source: CGSize) -> CGFloat {
        let w_scale = (target.width / source.width) as CGFloat
        let h_scale = (target.height / source.height) as CGFloat
        return ((w_scale < h_scale) ? w_scale : h_scale)
    }
    
    private func updateMinimumMaximumZoom(){
        let targetRect = CGRectInset(bounds, CONTENT_INSET, CONTENT_INSET)
        let zoomScale = ZoomScaleThatFits(targetRect.size, source: bounds.size)
        
        minimumZoomScale = zoomScale // Set the minimum and maximum zoom scales
        maximumZoomScale = zoomScale * CGFloat(ZOOM_LEVELS * ZOOM_LEVELS * ZOOM_LEVELS) // Max number of zoom levels
        zoomAmount = (maximumZoomScale - minimumZoomScale) / CGFloat(ZOOM_LEVELS)
    }
    
    private func zoomReset() {
        PDFScale = 1
        if zoomScale > minimumZoomScale {
            zoomScale = minimumZoomScale
        }
    }
    
    private func zoomRectForScale(scale: CGFloat, zoomPoint:CGPoint) -> CGRect {
        //Normalize current content size back to content scale of 1.0f
        var contentSize = CGSize()
        contentSize.width = (self.contentSize.width / zoomScale)
        contentSize.height = (self.contentSize.height / zoomScale)
    
        //translate the zoom point to relative to the content rect
        let x = (zoomPoint.x / bounds.size.width) * contentSize.width
        let y = (zoomPoint.y / bounds.size.height) * contentSize.height
    
        let translatedZoomPoint = CGPoint(x: x,y: y)
    
        //derive the size of the region to zoom to
        var zoomSize = CGSize()
        zoomSize.width = bounds.size.width / scale
        zoomSize.height = bounds.size.height / scale
    
        //offset the zoom rect so the actual zoom point is in the middle of the rectangle
        var zoomRect = CGRect()
        zoomRect.origin.x = translatedZoomPoint.x - zoomSize.width / 2.0
        zoomRect.origin.y = translatedZoomPoint.y - zoomSize.height / 2.0
        zoomRect.size.width = zoomSize.width
        zoomRect.size.height = zoomSize.height
    
        return zoomRect
    }
}

extension PDFPageView: UIScrollViewDelegate {
    /**
     A UIScrollView delegate callback, called when the user starts zooming.
     Return the current TiledPDFView.
     */
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
        return tiledPDFView
    }
    
    /**
     A UIScrollView delegate callback, called when the user stops zooming.
     When the user stops zooming, create a new Tiled
     PDFView based on the new zoom level and draw it on top of the old TiledPDFView.
     */
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        PDFScale = scale
    }
}
