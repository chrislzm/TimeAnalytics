//
//  TANavigationViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/21/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TANavigationViewController: UINavigationController {
    
    // Remove the progress view and all observers when we're done processing
    func didCompleteProcessing(_ notification:Notification) {
        print("Completed processing notification received")
        // Save everything to persistent data
        TAModel.sharedInstance().save()
        if let progressView = view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
}
