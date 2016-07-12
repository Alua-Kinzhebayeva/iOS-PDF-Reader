//
//  TiledView.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/22/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

internal final class TiledView: UIView {
    private var leftPdfPage: CGPDFPage?
    private let myScale: CGFloat
   
    init(frame:CGRect, scale: CGFloat, newPage: CGPDFPage) {
        myScale = scale
        leftPdfPage = newPage
        super.init(frame: frame)
        
        /*
        levelsOfDetail and levelsOfDetailBias determine how the layer is rendered at different zoom levels. This only matters while the view is zooming, because once the the view is done zooming a new TiledPDFView is created at the correct size and scale.
        */
        let tiledLayer = self.layer as! CATiledLayer
        tiledLayer.levelsOfDetail = 16
        tiledLayer.levelsOfDetailBias = 15
        
        let mainScreen = UIScreen.main() // Main screen
        let screenScale = mainScreen.scale // Main screen scale
        let screenBounds = mainScreen.bounds // Main screen bounds
        let w_pixels = screenBounds.size.width * screenScale
        let h_pixels = screenBounds.size.height * screenScale
        let max = ((w_pixels < h_pixels) ? h_pixels : w_pixels)
        let sizeOfTiles = ((max < 512.0) ? 512.0 : 1024.0) as CGFloat
        tiledLayer.tileSize = CGSize(width: sizeOfTiles, height: sizeOfTiles);
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        leftPdfPage = nil
    }
    
    override class func layerClass() -> AnyClass {
        return CATiledLayer.self
    }
    
    override func draw(_ r: CGRect) {
        /*
        UIView uses the existence of -drawRect: to determine if it should allow its CALayer to be invalidated, which would then lead to the layer creating a backing store and -drawLayer:inContext: being called.
        Implementing an empty -drawRect: method allows UIKit to continue to implement this logic, while doing the real drawing work inside of -drawLayer:inContext:.
        */
    }
    
    
    // Draw the CGPDFPageRef into the layer at the correct scale.
    override func draw(_ layer: CALayer, in con: CGContext) {
        // Fill the background with white.
        con.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        con.fill(bounds)
    
        con.saveGState()
        // Flip the context so that the PDF page is rendered right side up.
        con.translate(x: 0.0, y: bounds.size.height)
        con.scale(x: 1.0, y: -1.0)
    
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        con.scale(x: myScale, y: myScale)
        con.drawPDFPage(leftPdfPage!)
        con.restoreGState()
    }
}
