//
//  TAHealthKitAccess.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

class TAHealthKitAccessController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if HKHealthStore.isHealthDataAvailable() {
            print("Health data available")
            
            let delegate =  UIApplication.shared.delegate as! AppDelegate
            delegate.healthStore = HKHealthStore()
        } else {
            print("Health data not available")
        }
    }
}
