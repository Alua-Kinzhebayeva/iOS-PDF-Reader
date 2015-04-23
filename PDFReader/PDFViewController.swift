//  PDFViewController.swift
//  PDFReader
//
//  Created by ALUA KINZHEBAYEVA on 4/19/15.
//  Copyright (c) 2015 AK. All rights reserved.
//

import UIKit

class PDFViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    var collectionView: UICollectionView!
    var currentPDFPage: PDFPageView!
    var document: PDFDocument!
    var currentPageIndex: Int = 0
    
    init(document: PDFDocument){
        super.init(nibName: nil, bundle: nil);
        self.document = document
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.autoresizesSubviews = true
        self.view.autoresizingMask =  .FlexibleHeight | .FlexibleWidth
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        var scrollDirection = UICollectionViewScrollDirection.Horizontal
        layout.scrollDirection = scrollDirection
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0.0
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "page")
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.pagingEnabled = true
        self.view.addSubview(collectionView!)
        
        self.collectionView.autoresizesSubviews = true
        self.collectionView.autoresizingMask =  .FlexibleHeight | .FlexibleWidth
        
        self.view.backgroundColor = UIColor.clearColor()
        self.collectionView.backgroundColor = UIColor.clearColor()
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.document.pageCount().integerValue
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height-20)
    }
    
    //returns page view
    func pageView(page: Int, cell: UICollectionViewCell) -> UIScrollView{
        var pageTuple = self.document.getPage(page)
        var scrollView = PDFPageView(frame: cell.bounds)
        scrollView.setPDFPage(pageTuple.pageRef, backgroundImage: pageTuple.backgroundImage)
        self.currentPDFPage = scrollView
        var doubleTapOne = UITapGestureRecognizer(target: scrollView, action:Selector("handleDoubleTap:"))
        doubleTapOne.numberOfTapsRequired = 2;
        doubleTapOne.cancelsTouchesInView = false;
        scrollView.addGestureRecognizer(doubleTapOne)
        return scrollView
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("page", forIndexPath: indexPath) as! UICollectionViewCell

        var pageTuple = self.document.getPage(indexPath.row+1)
        var children = cell.subviews
        for view in children{
            view.removeFromSuperview()
        }
        cell.addSubview(self.pageView(indexPath.row, cell: cell))
            
        return cell
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.currentPageIndex =  Int(floor(self.collectionView.contentOffset.x / self.collectionView.bounds.size.width))
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        var newContentOffsetX = CGFloat(self.currentPageIndex) * self.collectionView.bounds.size.width
        self.collectionView.contentOffset = CGPointMake(newContentOffsetX, self.collectionView.contentOffset.y);
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
}



