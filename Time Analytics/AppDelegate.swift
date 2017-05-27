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
    var totalUpdateChunks = 0
    var chunksUpdated = 0
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
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willDownloadData(_:)), name: Notification.Name("willDownloadData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessData(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willCompleteUpdate(_:)), name: Notification.Name("willCompleteUpdate"), object: nil)

        return true
    }

    // MARK: Data update methods
    
    // Receives and stores the number of data chunks we need to download
    
    func willDownloadData(_ notification:Notification) {
        chunksUpdated = 0
        totalUpdateChunks = notification.object as! Int
    }
    
    // Increments number of data chunks successfully downloaded from Moves and parsed
    
    func didProcessData(_ notification:Notification) {
        chunksUpdated += 1
        
        // When all data chunks are complete, we launch Time Analytics data generation
        if totalUpdateChunks == chunksUpdated {
            TAModel.sharedInstance().generateTADataFromMovesData()
        }
    }

    // The model notifies us it is finished processing Moves data.
    
    func willCompleteUpdate(_ notification:Notification) {
        
        // Now import HealthKit data, if we are logged in. If the user is logging in for the first time, we do this instead in the login flow.
        if TAModel.sharedInstance().isLoggedIn() {
            TAModel.sharedInstance().updateHealthKitData()
        }

        // Update our internal lastCheckedForNewData variable that stores when we last checked for new data
        TAModel.sharedInstance().updateLastCheckedForNewData()
        
        // Save data to persistent store
        TAModel.sharedInstance().save()

        // Notify anyone who's listening that we're completely done with updating our data
        TAModel.sharedInstance().notifyDidCompleteUpdate()
    }
}

