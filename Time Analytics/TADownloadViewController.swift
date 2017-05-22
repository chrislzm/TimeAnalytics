//
//  TADownloadViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADownloadViewController:UIViewController {
    
    var dataChunksToDownload:Int = 0
    var dataChunksDownloaded:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let progressView = TAProgressView.instanceFromNib()
        setupOverlayView(progressView,view)
        progressView.fadeIn(nil)
        
        // Setup notifications so we know when to start processing data
        NotificationCenter.default.addObserver(self, selector: #selector(TADownloadViewController.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        
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
    
    func didCompleteDataChunk(_ notification:Notification) {
        dataChunksDownloaded += 1
        if dataChunksToDownload == dataChunksDownloaded {
            
            // Stop observing data chunk progress
            NotificationCenter.default.removeObserver(self)
            
            // Start observering for completion so we can remove the progressView when finished
            // Setup notifications so we know when to start processing data
            NotificationCenter.default.addObserver(self, selector: #selector(TADownloadViewController.didCompleteProcessing(_:)), name: Notification.Name("didCompleteProcessing"), object: nil)
            
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
    
    // Remove the progress view and all observers when we're done processing
    func didCompleteProcessing(_ notification:Notification) {
        if let progressView = view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                NotificationCenter.default.removeObserver(self)
                let stack = self.getCoreDataStack()
                stack.save()
                self.performSegue(withIdentifier: "DataDidFinishProcessing", sender: nil)
            }
        }
    }

}
