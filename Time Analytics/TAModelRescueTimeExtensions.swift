//
//  TAModelRescueTimeExtensions.swift
//  Time Analytics
//
//  Extensions to the Time Analytics Model (TAModel) class for supporting RescueTime data import.
//    -Under development
//    -Will implement Time Analytics data generation of TAActivitySegment entities from RescueTime data
//
//  Please note that the TAModel loadAllSessionData() will load the rescueTimeApiKey value from UserDefaults into the TANetClient singleton, and TAModel deleteAllSessionData() will clear the rescueTimeApiKey values from both TANetClient and UserDefaults.  
//
//  Created by Chris Leung on 6/2/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

extension TAModel {
    
    func getRescueTimeApiKey() -> String? {
        return TANetClient.sharedInstance.rescueTimeApiKey
    }
    
    func setRescueTimeApiKey(_ apiKey:String) {
        TANetClient.sharedInstance.rescueTimeApiKey = apiKey
        UserDefaults.standard.set(apiKey, forKey: "rescueTimeApiKey")
        UserDefaults.standard.synchronize()
    }
}
