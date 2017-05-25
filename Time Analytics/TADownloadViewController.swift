//
//  TADownloadViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TADownloadViewController:TADataUpdateViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startUpdatingWithProgressView()
    }
    
    override func didCompleteProcessing(_ notification:Notification) {
        removeProgressView() { () in
            self.performSegue(withIdentifier: "HealthKit", sender: nil)
        }
    }
}
