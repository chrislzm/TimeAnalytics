//
//  TAHealthKitAccess.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

class TAHealthKitAccessController: TAViewController {

    @IBAction func didPressContinue(_ sender: Any) {
        getHealthKitPermission()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !HKHealthStore.isHealthDataAvailable() {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "NoHealthKit", sender: nil)
            }
        }
    }
    
    func getHealthKitPermission() {
        
        authorizeHealthKit { (authorized,  error) -> Void in
            DispatchQueue.main.async {
                if !authorized {
                    self.displayErrorAlert("There was a problem with Health Kit authorization. Please try again by going to the Settings panel.")
                    self.performSegue(withIdentifier: "NoHealthKit", sender: nil)
                } else {
                    self.performSegue(withIdentifier: "ProcessHealthKitData", sender: nil)
                }
            }
        }
    }
    
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: Error?) -> Void)!) {
        
        let healthKitStore = getHealthStore()
        // State the health data type(s) we want to read from HealthKit.
        let readableTypes: Set<HKSampleType> = [HKWorkoutType.workoutType(), HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]

        healthKitStore.requestAuthorization(toShare: nil, read: readableTypes) { (success, error) -> Void in
            if( completion != nil ) {
                completion(success,error)
            }
        }
    }
}
