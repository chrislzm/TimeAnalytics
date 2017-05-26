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
        TAModel.sharedInstance().downloadAndProcessNewMovesData()
    }
    
    override func didCompleteUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView() { () in
                self.performSegue(withIdentifier: "HealthKit", sender: nil)
            }
        }
    }
}
