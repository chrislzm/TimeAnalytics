//
//  TADataUpdateController.swift
//  Time Analytics
//
//  Responsible for managing multiple progress indicator views for the different steps in the data processing flow.
//
//  Superclass. Never used directly. Has two subclasses: TADownloadViewController, TASettingsViewController
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
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willDownloadData(_:)), name: Notification.Name("willDownloadMovesData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willGenerateTAData(_:)), name: Notification.Name("willGenerateTAData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteMovesUpdate(_:)), name: Notification.Name("didCompleteMovesUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.willGenerateHKData(_:)), name: Notification.Name("willGenerateHKData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteAllUpdates(_:)), name: Notification.Name("didCompleteAllUpdates"), object: nil)
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
                self.progressView.defaultText = "Processing Moves Data"
                self.progressView.totalProgress = Float(dataChunks)
            }
        }
    }
    
    // Remove the TA data generation progressView since, since it doesn't know when data generation is complete
    // This method generally should be overwritten by subclasses, but should make sure to remove the progressview.
    func didCompleteMovesUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView(completionHandler: nil)
        }
    }
    
    // Display a new progressView for HealthKit data generation
    // The progressView will dismiss itself when download complete since HK data is processed in known# of stages
    func willGenerateHKData(_ notification:Notification) {
        DispatchQueue.main.async {
            self.progressView = TAProgressView.instanceFromNib()
            self.setupOverlayView(self.progressView,self.view)
            self.progressView.fadeIn(nil)
            self.progressView.defaultText = "Processing Health Data"
            self.progressView.totalProgress = Float(TAModel.Constants.HealthKitDataChunks)
        }
    }
    
    // Ensures all progress views are removed from the display
    func didCompleteAllUpdates(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView(completionHandler: nil)
        }
    }
}
