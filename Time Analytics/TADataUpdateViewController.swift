//
//  TADataUpdateController.swift
//  Time Analytics
//
//  Responsible for managing the progress indicator views that appear in the UI and syncing them with background data updates.
//
//  Created by Chris Leung on 5/25/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADataUpdateViewController:TAViewController {
    
    var progressView:TAProgressView!
    
    // MARK: Lifecycle
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Methods for updating data
    
    func startUpdatingWithProgressView() {
        
        // Setup notifications so we know when to update the progress view
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willDownloadData(_:)), name: Notification.Name("willDownloadData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willGenerateTAData(_:)), name: Notification.Name("willGenerateTAData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteUpdate(_:)), name: Notification.Name("didCompleteUpdate"), object: nil)
        
        // Create progress view that will dismiss itself since it will know exactly how much data will be processed

        TAModel.sharedInstance().downloadAndProcessNewMovesData()
    }
    
    func willDownloadData(_ notification:Notification) {
        let dataChunks = notification.object as! Int
        progressView = TAProgressView.instanceFromNib()
        progressView.totalProgress = Float(dataChunks)
        setupOverlayView(progressView,view)
        progressView.fadeIn(nil)
    }
    
    func willGenerateTAData(_ notification:Notification) {
        let dataChunks = notification.object as! Int
        DispatchQueue.main.async {
            if dataChunks > 0 {
                // Create a new progress view that we will have to dismiss manually, since the number of data chunks isn't exact
                self.progressView = TAProgressView.instanceFromNib()
                self.setupOverlayView(self.progressView,self.view)
                self.progressView.fadeIn(nil)
                self.progressView.defaultText = "Processing Data"
                self.progressView.totalProgress = Float(dataChunks)
            }
        }
    }
    
    func didCompleteUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView() { () in
                fatalError("Thus method should be overridden by subclasses--remove the progress view and notify the user here that processing is complete")
            }
        }
    }
    
    // Remove a progress view and its observers
    func removeProgressView(completionHandler: (()-> Void)?) {
        if let progressView = view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                NotificationCenter.default.removeObserver(self)
                if let closure = completionHandler {
                    closure()
                }
            }
        }
    }
    
    // Creates sets up overlay attributes, hides it, and adds it to the view hierarchy
    func setupOverlayView(_ view:UIView, _ parent:UIView) {
        
        if view is TAProgressView {
            (view as! TAProgressView).setupDefaultProperties()
        }
        
        view.alpha = 0
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = 100
        
        parent.addSubview(view)
        
        let horizontalConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        parent.addConstraints([horizontalConstraint,widthConstraint,heightConstraint,bottomConstraint])
    }
}
