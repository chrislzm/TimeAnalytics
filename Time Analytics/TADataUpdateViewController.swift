//
//  TADataUpdateController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/25/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADataUpdateViewController:UIViewController {
    
    var dataChunksToDownload:Int = 0
    var dataChunksDownloaded:Int = 0
    
    func startUpdatingWithProgressView() {
        
        let progressView = TAProgressView.instanceFromNib()
        setupOverlayView(progressView,view)
        progressView.fadeIn(nil)
        
        // Setup notifications so we know when to start processing data
        NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        
        TAModel.sharedInstance().downloadAndProcessNewMovesData() { (dataChunks, error) in
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
    
    func didCompleteDataChunk(_ notification:Notification) {
        dataChunksDownloaded += 1
        if dataChunksToDownload == dataChunksDownloaded {
            
            // Stop observing data chunk progress
            NotificationCenter.default.removeObserver(self)
            
            // Start observering for completion so we can remove the progressView when finished
            // Setup notifications so we know when to start processing data
            NotificationCenter.default.addObserver(self, selector: #selector(TADataUpdateViewController.didCompleteProcessing(_:)), name: Notification.Name("didCompleteProcessing"), object: nil)
            
            // Start generating our data
            dataChunksDownloaded = 0
            dataChunksToDownload = 0
            
            let progressView = TAProgressView.instanceFromNib()
            setupOverlayView(progressView,view)
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
    
    func didCompleteProcessing(_ notification:Notification) {
        removeProgressView() { () in
            fatalError("This method needs to be overridden by subclasses -- We should notify the user here of success")
        }
    }
}
