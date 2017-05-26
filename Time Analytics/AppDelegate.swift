//
//  AppDelegate.swift
//  Time Analytics
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
        TAModel.sharedInstance().autoUpdateMovesData(TANetClient.MovesApi.Constants.AutoUpdateMinutes)
        
        // Listen for data updates, so we can coordinate data download completion with processing
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didProcessData(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.willCompleteUpdate(_:)), name: Notification.Name("willCompleteUpdate"), object: nil)

        return true
    }

    // MARK: Data [auto]update methods
    
    func didProcessData(_ notification:Notification) {
        chunksUpdated += 1
        if totalUpdateChunks == chunksUpdated {
            TAModel.sharedInstance().generateTADataFromMovesData(nil)
        }
    }
    
    func willCompleteUpdate(_ notification:Notification) {
        // Reset properties
        totalUpdateChunks = 0
        chunksUpdated = 0

        TAModel.sharedInstance().updateMovesLastChecked()
        
        // Save data to persistent store
        TAModel.sharedInstance().save()
        NotificationCenter.default.post(name: Notification.Name("didCompleteUpdate"), object: nil)
    }
}

