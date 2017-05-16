//
//  Model.swift
//  Time Analytics
//
//  Convenience interface to the Time Analytics model for the controllers.
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import Foundation
import UIKit

class TAModel {
    
    // MARK: Moves API Methods
    func createMovesMoveObject(_ startTime:Date, _ endTime:Date, _ lastUpdate:Date?) {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "MovesMove", in: context)!
        let move = NSManagedObject(entity: entity, insertInto: context)
        move.setValue(startTime, forKey: "startTime")
        move.setValue(endTime, forKey: "endTime")
        move.setValue(lastUpdate, forKey: "lastUpdate")
        saveContext()
    }
    
    func createMovesPlaceObject(_ startTime:Date, _ endTime:Date, _ type:String,_ lat:Double,_ lon:Double,  _ lastUpdate:Date?,_ id:Int64?,_ name:String?,_ facebookPlaceId:String?,_ foursquareId:String?,_ foursquareCategoryIds:String?) {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "MovesPlace", in: context)!
        let place = NSManagedObject(entity: entity, insertInto: context)
        place.setValue(startTime, forKey: "startTime")
        place.setValue(endTime, forKey: "endTime")
        place.setValue(type, forKey: "type")
        place.setValue(lat, forKey: "lat")
        place.setValue(lon, forKey: "lon")
        place.setValue(lastUpdate, forKey: "lastUpdate")
        place.setValue(id, forKey: "id")
        place.setValue(name, forKey: "name")
        place.setValue(facebookPlaceId, forKey: "facebookPlaceId")
        place.setValue(foursquareId, forKey: "foursquareId")
        place.setValue(foursquareCategoryIds, forKey: "foursquareCategoryIds")
        saveContext()
    }
    
    func containsMovesObject(_ entityName:String, _ startTime:Date) -> Bool {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let pred = NSPredicate(format: "startTime == %@", argumentArray: [startTime])
        fr.predicate = pred
        var numResults = 0
        do {
            let result = try context.fetch(fr)
            numResults = result.count
            print("Found \(numResults) objects in data with startTime: \(startTime)")
        } catch {
            fatalError("Unable to access persistent data")
        }
        return numResults > 0
    }

    func deleteAllMovesData() {
        let context = getContext()
        let persistentStoreCoordinator = getPersistentStoreCoordinator()
        let moveFr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesMove")
        let deleteMoveRequest = NSBatchDeleteRequest(fetchRequest: moveFr)
        let placeFr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesPlace")
        let deletePlaceRequest = NSBatchDeleteRequest(fetchRequest: placeFr)
        
        do {
            try persistentStoreCoordinator.execute(deleteMoveRequest, with: context)
            try persistentStoreCoordinator.execute(deletePlaceRequest, with: context)
        } catch {
            fatalError("Unable to delete saved data")
        }
        saveContext()
    }

    
    func parseAndSaveMovesData(_ stories:[AnyObject]) {
        
        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        
        for story in stories {
            if let segments = story[NetClient.MovesApi.JSONResponseKeys.Segments] as? [AnyObject] {
                for segment in segments {
                    // TODO: Don't force unwrap optionals here
                    let type = segment[NetClient.MovesApi.JSONResponseKeys.Segment.SegmentType] as! String
                    let startTime = dateFormatter.date(from: segment[NetClient.MovesApi.JSONResponseKeys.Segment.StartTime] as! String)!
                    let endTime = dateFormatter.date(from: segment[NetClient.MovesApi.JSONResponseKeys.Segment.EndTime] as! String)!
                    var lastUpdate:Date? = nil
                    if let optionalLastUpdate = segment[NetClient.MovesApi.JSONResponseKeys.Segment.LastUpdate] as? String{
                        lastUpdate = dateFormatter.date(from: optionalLastUpdate)
                    }
                    
                    switch type {
                    case NetClient.MovesApi.JSONResponseValues.Segment.Move:
                        if (!containsMovesObject("MovesMove", startTime)) {
                            createMovesMoveObject(startTime, endTime, lastUpdate)
                        }
                    case NetClient.MovesApi.JSONResponseValues.Segment.Place:
                        // TODO: Don't force unwrap optionals below
                        let place = segment[NetClient.MovesApi.JSONResponseKeys.Segment.Place] as! [String:AnyObject]
                        let id = place[NetClient.MovesApi.JSONResponseKeys.Place.Id] as? Int64
                        let name = place[NetClient.MovesApi.JSONResponseKeys.Place.Name] as? String
                        let type = place[NetClient.MovesApi.JSONResponseKeys.Place.PlaceType] as! String
                        let facebookPlaceId = place[NetClient.MovesApi.JSONResponseKeys.Place.FacebookPlaceId] as? String
                        let foursquareId = place[NetClient.MovesApi.JSONResponseKeys.Place.FoursquareId] as? String
                        var foursquareCategoryIds:String?
                        if let optionalFoursquareCategoryIds = place[NetClient.MovesApi.JSONResponseKeys.Place.FoursquareCategoryIds] as? [String] {
                            foursquareCategoryIds = String()
                            for fourSquareCategoryId in optionalFoursquareCategoryIds {
                                foursquareCategoryIds?.append(fourSquareCategoryId + ",")
                            }
                        }
                        let coordinates = place[NetClient.MovesApi.JSONResponseKeys.Place.Location] as! [String:Double]
                        let lat = coordinates[NetClient.MovesApi.JSONResponseKeys.Place.Latitude]!
                        let lon = coordinates[NetClient.MovesApi.JSONResponseKeys.Place.Longitude]!
                        
                        if(!containsMovesObject("MovesPlace", startTime)) {
                            createMovesPlaceObject(startTime, endTime, type, lat, lon, lastUpdate, id, name, facebookPlaceId, foursquareId, foursquareCategoryIds)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: User Defaults Methods

    func loadMovesSessionData() {
        // Check first if we even have an access token expiration date
        if let accessTokenExpiration = UserDefaults.standard.value(forKey: "movesAccessTokenExpiration") as? Date {
            
            // If the access token is still valid
            if Date() < accessTokenExpiration {
                // Save the session information into our Net Client
                NetClient.sharedInstance().movesAccessTokenExpiration = accessTokenExpiration
                NetClient.sharedInstance().movesAccessToken = UserDefaults.standard.value(forKey: "movesAccessToken") as? String
                NetClient.sharedInstance().movesAuthCode = UserDefaults.standard.value(forKey: "movesAuthCode") as? String
                NetClient.sharedInstance().movesRefreshToken = UserDefaults.standard.value(forKey: "movesRefreshToken") as? String
                NetClient.sharedInstance().movesUserId = UserDefaults.standard.value(forKey: "movesUserId") as? UInt64
            }
        }
        
    }
    
    func saveMovesLoginInfo(_ authCode:String, _ userId:UInt64, _ accessToken:String,_ accessTokenExpiration:Date,_ refreshToken:String) {
        UserDefaults.standard.set(authCode, forKey: "movesAuthCode")
        UserDefaults.standard.set(userId, forKey: "movesUserId")
        UserDefaults.standard.set(accessToken, forKey: "movesAccessToken")
        UserDefaults.standard.set(accessTokenExpiration, forKey: "movesAccessTokenExpiration")
        UserDefaults.standard.set(refreshToken, forKey: "movesRefreshToken")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Helper Functions
    
    func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func getContext() -> NSManagedObjectContext {
        return getAppDelegate().persistentContainer.viewContext
    }
    
    func getPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        return getAppDelegate().persistentContainer.persistentStoreCoordinator
    }
    
    func saveContext() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.saveContext()
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> Model {
        struct Singleton {
            static var sharedInstance = Model()
        }
        return Singleton.sharedInstance
    }
}
