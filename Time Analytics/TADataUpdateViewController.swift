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
        DispatchQueue.main.async {
            let dataChunks = notification.object as! Int
            self.progressView = TAProgressView.instanceFromNib()
            self.progressView.totalProgress = Float(dataChunks)
            self.setupOverlayView(self.progressView,self.view)
            self.progressView.fadeIn(nil)
        }
    }
    
    func willGenerateTAData(_ notification:Notification) {
        DispatchQueue.main.async {
            let dataChunks = notification.object as! Int
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
}
