//
//  TAHealthKitAccessController.swift
//  Time Analytics
//
//  Attempts to gain access authorization to user's HealthKit Health Store. Decides where to segue depending on the result. (Either into the app, or onto processing HealthKit data.)
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

class TAHealthKitAccessController: TAViewController {

    // MARK: Outlets
    @IBAction func didPressContinue(_ sender: Any) {
        getHealthKitPermission()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If no Health Store available, skip this step and go directly into the app
        if !HKHealthStore.isHealthDataAvailable() {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "NoHealthKit", sender: nil)
            }
        }
    }
    
    // MARK: HealthKit Authorization
    
    // Gets authorization to read HealthKit data from the Health Store. Segues either into the app upon failure or denial of authorization, or 
    
    func getHealthKitPermission() {
        TAModel.sharedInstance.authorizeHealthKit { (authorized,  error) -> Void in
            DispatchQueue.main.async {
                
                // If error, display message and segue when the user taps "OK"
                guard error == nil else {
                    self.displayErrorAlert("There was a problem with Health Kit authorization. We are unable to import your HealthKit data.") { (uiAlertAction) in
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "NoHealthKit", sender: nil)
                        }
                    }
                    return
                }
                if !authorized {
                    self.performSegue(withIdentifier: "NoHealthKit", sender: nil)
                } else {
                    // We're authorized
                    self.performSegue(withIdentifier: "ProcessHealthKitData", sender: nil)
                }
            }
        }
    }
}
