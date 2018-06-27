//
//  PDFViewUIProperties.swift
//  PDFReader
//
//  Created by Vrushali Wani on 26/06/2018.
//  Copyright © 2018 mytrus. All rights reserved.
//

import Foundation

public struct PDFViewUIProperties {
    /// Title for the pdf
    public var title: String?
    
    /// font for the title label
    public var titleFont: UIFont?
    
    /// subtitle for the pdf
    public var subtitle: String?
    
    /// font for the subtitle label
    public var subtitleFont: UIFont?
    
    /// image for back button
    public var backButtonImage: UIImage?
    
    /// Whether or not the thumbnails bar should be enabled
    public var isThumbnailsEnabled: Bool
    
    /// Color of the line view
    public var lineViewColor: UIColor?
    
    /**
     Returns newly initialised PDFViewUIProperties
     
     - title: Title for the pdf
     - titleFont: font for the title label
     - subtitle: subtitle for the pdf
     - subtitleFont: font for the subtitle label
     - backButtonImage: image for back button
     - isThumbnailsEnabled: whether or not the thumbnails bar should be enabled
     - lineViewColor: color for the line view
     returns: a `PDFViewUIProperties`
     */
    public init?(title: String?, titleFont: UIFont?, subtitle: String?, subtitleFont: UIFont?, backButtonImage: UIImage?, isThumbnailsEnabled: Bool = true, lineViewColor: UIColor?) {
        self.title = title
        self.titleFont = titleFont
        self.subtitle = subtitle
        self.subtitleFont = subtitleFont
        self.backButtonImage = backButtonImage
        self.isThumbnailsEnabled = isThumbnailsEnabled
        self.lineViewColor = lineViewColor
    }
}
