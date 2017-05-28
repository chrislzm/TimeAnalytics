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

class TAProcessHealthKitDataController: TADataUpdateViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start HealthKit data import
        TAModel.sharedInstance().updateHealthKitData()
    }
    
    override func didCompleteAllUpdates(_ notification: Notification) {
        DispatchQueue.main.async {
            super.didCompleteAllUpdates(notification)
            // Make sure we save data to persistent store since the import was done on a background context
            let stack = self.getCoreDataStack()
            stack.save()
            self.performSegue(withIdentifier: "FinishedProcessingHealthKitData", sender: nil)
        }
    }
}
