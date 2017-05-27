//
//  TADataUpdateController.swift
//  Time Analytics
//
//  Responsible for managing multiple progress indicator views for the different steps in the data processing flow.
//
//  Never used directly. Has two subclasses: TADownloadViewController, TASettingsViewController
//
//  Created by Chris Leung on 5/25/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADataUpdateViewController:TAViewController {
    
    var progressView:TAProgressView! // Stores reference to the currently displayed progressView
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup notifications so we know when to display and update the progress view
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willDownloadData(_:)), name: Notification.Name("willDownloadData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willGenerateTAData(_:)), name: Notification.Name("willGenerateTAData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteUpdate(_:)), name: Notification.Name("didCompleteUpdate"), object: nil)
    }

    // MARK: Notification Observers
    
    // Display progressView for data download with the correct number of data chunks
    // The progressView will dismiss itself when download complete since it knows when all data chunks have been received
    func willDownloadData(_ notification:Notification) {
        DispatchQueue.main.async {
            let dataChunks = notification.object as! Int
            self.progressView = TAProgressView.instanceFromNib()
            self.progressView.totalProgress = Float(dataChunks)
            self.setupOverlayView(self.progressView,self.view)
            self.progressView.fadeIn(nil)
        }
    }
    
    // Display a new progressView for TA data generation
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
    
    // Remove the TA data generation progressView since, since it doesn't know when data generation is complete
    func didCompleteUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView() { () in
                fatalError("Thus method should be overridden by subclasses--remove the progress view and notify the user here that processing is complete")
            }
        }
    }
}
