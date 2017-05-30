//
//  AppDelegate.swift
//  Time Analytics
//
//  Has two important responsibilities:
//
//  * Moves login auth flow: Sends a notification if the Moves app gave us an authorization code.
//
//  * Synchronizes the data update process via notifications. Because this process involves many steps that involve waiting (for network or for background processes to complete) we need to use notifications to synchronize everything. App Delegate is the one that observes these notificatons and does the synchronizing. Here's how the process flows:
//
//  1. A call to TAModel.downloadAndProcessNewMovesData() (by auto-update or by the user) starts the entire data update process
//
//  2. "willDownloadMovesData" notification is sent by TAModel along with the # of "chunks" of data that will need to be downloaded and processed
//
//  3. "didProcessMovesDataChunk" notification is sent by TAModel every time every time a chunk of data has been successfully downloaded and processed
//
//  4. When AppDelegate sees we have completed processing all data chunks, it calls TAModel.generateTADataFromMovesData() which begins generating our internal "TA" data from the Moves data
//
//  5. If there is data to generate, TAModel sends "notifyWillGenerateTAData" notification before it starts
//
//  6. If there is no data to generate, or data generation is complete, TAModel sends "notifyDidCompleteMovesUpdate" notification
//
//  7. AppDelegate then starts importing HealthKit data using TAModel.updateHealthKitData(), unless we're not logged in (see didCompleteMovesUpdate method below).
//
//  8. TAModel (Health Kit Extension) sends a "didProcessHealthKitDataChunk" notification every time it processes a chunk of HealthKit data. There are a finite number of stages to this process that we know in advanced.
//
//  9. When AppDelegate sees we have processed all chunks of HealthKit data, it updates the internal session variable of the last time we checked for data, and then sends a final "didCompleteAllUpdates" notification.
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
    
    // MARK: Handle Moves Auth Code
    
    // If we received an authorization code from the Moves app, package it in a notification and send it. TALoginViewController will be listening for this notification.
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let query = url.query {
            let keyValues = query.components(separatedBy: "&")
            for keyValue in keyValues {
                let keyValuePair = keyValue.components(separatedBy: "=")
                if keyValuePair[0] == "code" {
                    NotificationCenter.default.post(name: Notification.Name("didGetMovesAuthCode"), object: nil, userInfo: [AnyHashable("code"):keyValuePair[1]])
                }
            }
        }
        return true
    }
    
    // MARK: Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Restore all session data
        TAModel.sharedInstance.loadAllSessionData()
        
        // Start regular autoupdates in the background
        TAModel.sharedInstance.startAutoUpdate()
        
        // Listen for data updates, so we can coordinate data download completion and data processing
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willDownloadMovesData(_:)), name: Notification.Name("willDownloadMovesData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessMovesData(_:)), name: Notification.Name("didProcessMovesDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessHealthKitData(_:)), name: Notification.Name("didProcessHealthKitDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didCompleteMovesUpdate(_:)), name: Notification.Name("didCompleteMovesUpdate"), object: nil)

        return true
    }
    
    // MARK: Notification Handlers for Coordinating Data Processing
    
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
            TAModel.sharedInstance.generateTADataFromMovesData()
        }
    }
    
    // The model notifies us it is finished processing Moves data.
    func didCompleteMovesUpdate(_ notification:Notification) {
        // Reset variables before processing HealthKit data
        healthKitChunksProcessed = 0
        totalHealthKitChunks = TAModel.HealthKitDataChunks
        
        // If we are logged in, now import HealthKit data.
        // (During the first login, the user is still not fully logged in at this point. They need to first authorize our access to HealthKit on a separate screen. We begin the HealthKit import there manually.
        if TAModel.sharedInstance.isLoggedIn() {
            TAModel.sharedInstance.updateHealthKitData()
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
        TAModel.sharedInstance.updateLastCheckedForNewData()
        
        // Notify anyone who's listening that we're completely done with updating our data
        TAModel.sharedInstance.notifyDidCompleteAllUpdates()
    }
}

