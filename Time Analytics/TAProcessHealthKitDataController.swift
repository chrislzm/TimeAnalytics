//
//  TAProcessHealthKitDataController.swift
//  Time Analytics
//
//  Imports HealthKit data and automatically segues when complete.
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TAProcessHealthKitDataController: TAViewController {
    
    var dataChunksToImport = 0
    var dataChunksImported = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup notifications so we know when we finished importing data
        NotificationCenter.default.addObserver(self, selector: #selector(TAProcessHealthKitDataController.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        
        // There are a constant amount of steps in the data processing flow
        dataChunksToImport = TAModel.Constants.HealthKitDataChunks

        // Setup the progressView
        let progressView = TAProgressView.instanceFromNib()
        progressView.defaultText = "Processing Data"
        progressView.totalProgress = Float(dataChunksToImport)
        setupOverlayView(progressView, self.view)
        progressView.fadeIn(nil)
        
        // Start data import
        TAModel.sharedInstance().updateHealthKitData()
    }
    
    func didCompleteDataChunk(_ notification:Notification) {
        dataChunksImported += 1
        // If we have completed processing
        if dataChunksImported == dataChunksToImport {
            DispatchQueue.main.async {
                // Make sure we save data to persistent store since the import was done on a background context
                let stack = self.getCoreDataStack()
                stack.save()
                
                self.removeProgressView() { () in
                    self.performSegue(withIdentifier: "FinishedProcessingHealthKitData", sender: nil)
                }
            }
        }
    }
}
