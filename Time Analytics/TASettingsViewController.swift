//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {
    
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    
    var dataChunksToDownload:Int = 0
    var dataChunksDownloaded:Int = 0
    
    @IBAction func downloadAllUserDataButtonPressed(_ sender: Any) {
        let progressView = TAProgressView.instanceFromNib()
        setupOverlayView(progressView)
        progressView.fadeIn(nil)

        // Setup notifications so we know when to start processing data
        NotificationCenter.default.addObserver(self, selector: #selector(TASettingsViewController.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)

        TAModel.sharedInstance().downloadAndProcessAllMovesData() { (dataChunks, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    print(error!)
                    return
                }
                progressView.totalProgress = Float(dataChunks)
                self.dataChunksToDownload = dataChunks
            }
            
        }
    }
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().downloadAndProcessMovesDataInRange(startDate.date, endDate.date) { (error) in
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment"])
    }
    
    func didCompleteDataChunk(_ notification:Notification) {
        print("Saw data chunk downloaded \(dataChunksDownloaded) of \(dataChunksToDownload)")
        dataChunksDownloaded += 1
        if dataChunksToDownload == dataChunksDownloaded {

            // Stop observing data chunk progress
            NotificationCenter.default.removeObserver(self)
            
            // Start observering for completion so we can remove the progressView when finished
            // Setup notifications so we know when to start processing data
            NotificationCenter.default.addObserver(self.navigationController!, selector: #selector(TANavigationViewController.didCompleteProcessing(_:)), name: Notification.Name("didCompleteProcessing"), object: nil)
            
            // Start generating our data
            dataChunksDownloaded = 0
            dataChunksToDownload = 0
            
            let progressView = TAProgressView.instanceFromNib()
            setupOverlayView(progressView)
            progressView.fadeIn(nil)
            progressView.defaultText = "Processing Data"
            
            TAModel.sharedInstance().generateTADataFromMovesData() { (dataChunks, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                
                DispatchQueue.main.async {
                    progressView.totalProgress = Float(dataChunks)
                }
            }
        }
    }
    
    // Remove the progress view and all observers when we're done processing
    func didCompleteProcessing(_ notification:Notification) {
        print("Completed processing notification received")
        if let progressView = self.navigationController?.view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    // Creates sets up overlay attributes, hides it, and adds it to the navigation controller view hierarchy
    func setupOverlayView(_ view:UIView) {
        
        if view is TAProgressView {
            (view as! TAProgressView).setupDefaultProperties()
        }
        
        view.alpha = 0
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = 100
        let navControllerView = self.navigationController!.view!
        
        navControllerView.addSubview(view)
        
        let horizontalConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        self.navigationController?.view.addConstraints([horizontalConstraint,widthConstraint,heightConstraint,bottomConstraint])
    }
}

