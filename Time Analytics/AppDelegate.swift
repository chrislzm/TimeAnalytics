//
//  AppDelegate.swift
//  Time Analytics
//
//  Has two important responsibilities:
//
//    1. Checks whether the Moves app gave us an authorization code. This is part of the Moves login auth flow.
//
//    2. Manages data download and processing.
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import CoreData
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    var window: UIWindow?
    var totalMovesChunks = 0
    var movesChunksProcessed = 0
    var totalHealthKitChunks = 0
    var healthKitChunksProcessed = 0
    var query:String?
    let stack = CoreDataStack(modelName: "Managed Objects")!
    var healthStore = HKHealthStore()
    
    // MARK: Lifecycle
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let query = url.query {
            let keyValues = query.components(separatedBy: "&")
            for keyValue in keyValues {
                let keyValuePair = keyValue.components(separatedBy: "=")
                if keyValuePair[0] == "code" {
                    NotificationCenter.default.post(name: Notification.Name("didGetMovesAuthCode"), object: nil, userInfo: [AnyHashable("code"):keyValuePair[1]])
                } else if keyValuePair[0] == "error" {
                    //TODO: Implement -- see error codes on https://dev.moves-app.com/docs/authentication
                }
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Restore moves session data
        TAModel.sharedInstance().loadMovesSessionData()
        
        // Start regular autoupdates in the background
        TAModel.sharedInstance().autoUpdateMovesData(TANetClient.MovesApi.Constants.AutoUpdateMinutes)
        
        // Listen for data updates, so we can coordinate data download completion and data processing
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willDownloadMovesData(_:)), name: Notification.Name("willDownloadMovesData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessMovesData(_:)), name: Notification.Name("didProcessMovesDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessHealthKitData(_:)), name: Notification.Name("didProcessHealthKitDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didCompleteMovesUpdate(_:)), name: Notification.Name("didCompleteMovesUpdate"), object: nil)

        return true
    }

    // MARK: Data update methods
    
    // Receives and stores the number of data chunks we need to download from Moves
    func willDownloadMovesData(_ notification:Notification) {
        // Reset variables before processing Moves data
        movesChunksProcessed = 0
        totalMovesChunks = notification.object as! Int
    }
    
    // Increments number of data chunks successfully downloaded from Moves and parsed
    func didProcessMovesData(_ notification:Notification) {
        movesChunksProcessed += 1
        if movesChunksProcessed == totalMovesChunks {
            // Done downloading Moves data, start generating TA Data
            TAModel.sharedInstance().generateTADataFromMovesData()
        }
    }
    
    // The model notifies us it is finished processing Moves data.
    func didCompleteMovesUpdate(_ notification:Notification) {
        // Reset variables before processing HealthKit data
        healthKitChunksProcessed = 0
        totalHealthKitChunks = TAModel.Constants.HealthKitDataChunks
        
        // If we are logged in, now import HealthKit data.
        // (During the first login, the user is still not fully logged in at this point. They need to first authorize our access to HealthKit on a separate screen. We begin the HealthKit import there manually.
        if TAModel.sharedInstance().isLoggedIn() {
            TAModel.sharedInstance().updateHealthKitData()
        }
    }
    
    // Increments number of HealthKit data chunks successfully processed
    func didProcessHealthKitData(_ notification:Notification) {
        healthKitChunksProcessed += 1
        if healthKitChunksProcessed == totalHealthKitChunks {
            didCompleteAllUpdates()
        }
    }
    
    // Final step in updating data
    func didCompleteAllUpdates() {
        // Update our internal lastCheckedForNewData variable that stores when we last checked for new data
        TAModel.sharedInstance().updateLastCheckedForNewData()
        
        // Notify anyone who's listening that we're completely done with updating our data
        TAModel.sharedInstance().notifyDidCompleteAllUpdates()
    }
}

