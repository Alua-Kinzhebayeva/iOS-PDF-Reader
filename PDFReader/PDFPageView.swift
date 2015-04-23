//
//  PDFPageView.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/23/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import Foundation
import UIKit

private var myContext = 0

class PDFPageView: UIScrollView, UIScrollViewDelegate{
    
    let ZOOM_LEVELS = 2
    let ZOOM_STEP = 2
    let CONTENT_INSET = 2 as CGFloat
    
    // A low resolution image of the PDF page that is displayed until the TiledPDFView renders its content.
    var _backgroundImageView: UIImageView?
    // The TiledPDFView that is currently front most.
    var _tiledPDFView: TiledView!
    // The old TiledPDFView that we draw on top of when the zooming stops.
    var _oldTiledPDFView: TiledView!
    var _PDFPage: CGPDFPageRef!
    var _PDFScale: CGFloat?
    var _frame: CGRect?
    var zoomAmount: CGFloat?
    var isAtMaximumZoom: Bool = false

    func ZoomScaleThatFits(target: CGSize, source: CGSize) -> CGFloat{
        
        var w_scale = (target.width / source.width) as CGFloat
        var h_scale = (target.height / source.height) as CGFloat
        
        return ((w_scale < h_scale) ? w_scale : h_scale)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.bouncesZoom = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.delegate = self
        self.autoresizesSubviews = true
        self.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        self.addObserver(self, forKeyPath: "frame", options: .New, context: &myContext)

    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if keyPath == "frame" {
                if self._frame!.size.width != self.frame.size.width{
                    _frame = self.frame;
                    
                    var pageRect = CGPDFPageGetBoxRect(self._PDFPage, kCGPDFMediaBox)
                    self._PDFScale = min(self.frame.size.width/pageRect.size.width, self.frame.size.height/pageRect.size.height);
                    pageRect.size = CGSizeMake(pageRect.size.width*self._PDFScale!, pageRect.size.height*self._PDFScale!);
                    var newTiledView = TiledView(frame: pageRect, scale: self._PDFScale!)
                    newTiledView.setLeftPage(self._PDFPage)
                    self.addSubview(newTiledView)
                    self._tiledPDFView.removeFromSuperview()
                    self._tiledPDFView = newTiledView
                    self.contentSize = self._tiledPDFView.bounds.size;
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    deinit {
        self.removeObserver(self, forKeyPath: "frame", context: &myContext)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateMinimumMaximumZoom(){
        
        var targetRect = CGRectInset(self.bounds, CONTENT_INSET, CONTENT_INSET);
        var zoomScale = ZoomScaleThatFits(targetRect.size, source: self.bounds.size);
    
        self.minimumZoomScale = zoomScale // Set the minimum and maximum zoom scales
    
        self.maximumZoomScale = zoomScale * CGFloat(ZOOM_LEVELS*ZOOM_LEVELS*ZOOM_LEVELS) // Max number of zoom levels
    
        self.zoomAmount = (self.maximumZoomScale - self.minimumZoomScale) / CGFloat(ZOOM_LEVELS)
    }
    
    func zoomReset(){
        self._PDFScale = 1;
        if (self.zoomScale > self.minimumZoomScale)
        {
            self.zoomScale = self.minimumZoomScale;
        }
    }
    
    func setPDFPage(PDFPageRef: CGPDFPageRef, backgroundImage: UIImage){
       
        self.updateMinimumMaximumZoom()
        self.zoomReset()
        
        self._PDFPage = PDFPageRef;
        
        // Determine the size of the PDF page.
        var pageRect = CGPDFPageGetBoxRect(self._PDFPage, kCGPDFMediaBox)
        
        self._PDFScale = min(self.frame.size.width/pageRect.size.width, self.frame.size.height/pageRect.size.height);
        pageRect.size = CGSizeMake(pageRect.size.width*self._PDFScale!, pageRect.size.height*self._PDFScale!);

        if(CGRectIsEmpty(pageRect)) {return}
        
        if (self._backgroundImageView != nil) {
            self._backgroundImageView?.removeFromSuperview()
        }
        
        self._backgroundImageView = UIImageView(image: backgroundImage)
        self._backgroundImageView!.frame = pageRect;
        self._frame = pageRect;
        
        self.addSubview(self._backgroundImageView!)
        self.sendSubviewToBack(self._backgroundImageView!)
        
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
        self._tiledPDFView = TiledView(frame: pageRect, scale: self._PDFScale!)
        //TODO change func name
        self._tiledPDFView.setLeftPage(self._PDFPage)
        self.addSubview(self._tiledPDFView)

    }
    
    // Use layoutSubviews to center the PDF page in the view.
    override func layoutSubviews(){
        super.layoutSubviews()
    
        // Center the image as it becomes smaller than the size of the screen.
    
        var boundsSize = self.bounds.size;
        var frameToCenter = self._tiledPDFView.frame;
    
        // Center horizontally.
    
        if (frameToCenter.size.width < boundsSize.width){
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        }
        else{
            frameToCenter.origin.x = 0
        }
    
        // Center vertically.
    
        if (frameToCenter.size.height < boundsSize.height){
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        }
        else{
            frameToCenter.origin.y = 0
        }
    
        self._tiledPDFView.frame = frameToCenter;
        self._backgroundImageView!.frame = frameToCenter;
        //    self.backgroundImageView.hidden = YES;
    
        //self.tiledPDFView.frame = frameToCenter;
    
        /*
        To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
        If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
        */
        self._tiledPDFView.contentScaleFactor = 1.0;
    }
    
    /*
    A UIScrollView delegate callback, called when the user starts zooming.
    Return the current TiledPDFView.
    */
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
        return self._tiledPDFView;
    }
    
    /*
    A UIScrollView delegate callback, called when the user begins zooming.
    When the user begins zooming, remove the old TiledPDFView and set the current TiledPDFView to be the old view so we can create a new TiledPDFView when the zooming ends.
    */
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
    
    }
    
    /*
    A UIScrollView delegate callback, called when the user stops zooming.
    When the user stops zooming, create a new Tiled
    PDFView based on the new zoom level and draw it on top of the old TiledPDFView.
    */
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        self._PDFScale = scale;
    }
    
    func zoomRectForScale(scale: CGFloat, zoomPoint:CGPoint) -> CGRect {
    
        //Normalize current content size back to content scale of 1.0f
        var contentSize = CGSize()
        contentSize.width = (self.contentSize.width / self.zoomScale);
        contentSize.height = (self.contentSize.height / self.zoomScale);
    
        //translate the zoom point to relative to the content rect
        var x = (zoomPoint.x / self.bounds.size.width) * contentSize.width;
        var y = (zoomPoint.y / self.bounds.size.height) * contentSize.height;
    
        var translatedZoomPoint = CGPoint(x: x,y: y)
        //scale = self.zoomScale;
    
        //derive the size of the region to zoom to
        var zoomSize = CGSize()
        zoomSize.width = self.bounds.size.width / scale
        zoomSize.height = self.bounds.size.height / scale
    
        //offset the zoom rect so the actual zoom point is in the middle of the rectangle
        var zoomRect = CGRect()
        zoomRect.origin.x = translatedZoomPoint.x - zoomSize.width / 2.0;
        zoomRect.origin.y = translatedZoomPoint.y - zoomSize.height / 2.0;
        zoomRect.size.width = zoomSize.width;
        zoomRect.size.height = zoomSize.height;
    
        return zoomRect;
    }
    
    
    func handleDoubleTap(tapRecognizer: UITapGestureRecognizer){
        var newScale = self.zoomScale * CGFloat(ZOOM_STEP)
        if(newScale >= self.maximumZoomScale){
            newScale = self.minimumZoomScale
        }
        self._backgroundImageView!.hidden = true
        var zoomRect = self.zoomRectForScale(newScale, zoomPoint: tapRecognizer.locationInView(tapRecognizer.view))
        self.zoomToRect(zoomRect, animated: true)
        self._backgroundImageView!.hidden = false;
    }
    
    func resetPage(){
        self._backgroundImageView?.removeFromSuperview()
        self._tiledPDFView.removeFromSuperview()
        self._oldTiledPDFView.removeFromSuperview()
    }
    
}
