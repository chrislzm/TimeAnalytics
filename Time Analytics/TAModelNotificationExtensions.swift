//
//  TAModelNotificationExtensions.swift
//  Time Analytics
//
//  Contains all send notification methods used in Time Analytics.
//
//  Only used by TAModel and AppDelegate classes.
//
//  Created by Chris Leung on 5/27/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

extension TAModel {
    
    // Called by TAModel when downloading Moves data has commenced. Object will contain the number of requests that need to complete.
    func notifyWillDownloadMovesData(dataChunks:Int) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("willDownloadMovesData"), object: dataChunks)
        }
    }
    
    // Called by TAModel whenever a Moves "chunk" has completed. For data downloads, this will be # of requests. For generating data from moves data, this will be the approximate number of records. The number is approximate, since Moves data is messy, and much of it gets consolidated.
    func notifyDidProcessMovesDataChunk() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("didProcessMovesDataChunk"), object: nil)
        }
    }
    
    // Called by TAModel when we have completed parsing all downloaded data, and will begin using it to generate TA data
    func notifyWillGenerateTAData(dataChunks:Int) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("willGenerateTAData"), object: dataChunks)
        }
        
    }
    
    // Called by TAModel when all Time Analytics data has finished generating from Moves data.
    func notifyDidCompleteMovesUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("didCompleteMovesUpdate"), object: nil)
        }
    }
    
    // Called by TAModel HealthKit Extension when we begin importing HealthKit data
    func notifyWillGenerateHKData() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("willGenerateHKData"), object: nil)
        }
    }
    
    // Called by TAModel HealthKit Extension when it has completed a chunk of HealthKit data
    func notifyDidProcessHealthKitDataChunk() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("didProcessHealthKitDataChunk"), object: nil)
        }
    }
    
    // Called by AppDelegate when *all* data has been saved and cleanup has been done.
    func notifyDidCompleteAllUpdates() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("didCompleteAllUpdates"), object: nil)
        }
    }
    
    // Called by TAModel when there was an error parsing Moves JSON data from a 3rd party API
    func notifyMovesDataParsingError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("movesDataParsingError"), object: nil)
        }
    }
    
    // Called by TAModel when TANetClient has informed us there was a network error preventing us from downloading data from Moves
    func notifyDownloadMovesDataError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("downloadMovesDataError"), object: nil)
        }
    }
    
    // Called by TAModel when there was an error reading Health Store data
    func notifyHealthDataReadError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("healthDataReadError"), object: nil)
        }
    }
}
