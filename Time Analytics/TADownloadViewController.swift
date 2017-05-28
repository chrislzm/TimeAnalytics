//
//  TADownloadViewController.swift
//  Time Analytics
//
//  Begins the Moves data download and processing flow. Upon completion, automatically segues to the HealthKit data import view. 
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADownloadViewController:TADataUpdateViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TAModel.sharedInstance().downloadAndProcessNewMovesData()
        
        errorCompletionHandler = { () in
            self.performSegue(withIdentifier: "BackToLogin", sender: nil)
        }
    }
    
    override func didCompleteMovesUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView() { () in
                self.performSegue(withIdentifier: "HealthKit", sender: nil)
            }
        }
    }

}
