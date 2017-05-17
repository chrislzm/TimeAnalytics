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
        let entity = NSEntityDescription.entity(forEntityName: "MovesMoveSegment", in: context)!
        let movesMoveSegment = NSManagedObject(entity: entity, insertInto: context)
        movesMoveSegment.setValue(startTime, forKey: "startTime")
        movesMoveSegment.setValue(endTime, forKey: "endTime")
        movesMoveSegment.setValue(lastUpdate, forKey: "lastUpdate")
        saveContext()
    }
    
    func createMovesPlaceObject(_ startTime:Date, _ endTime:Date, _ type:String,_ lat:Double,_ lon:Double,  _ lastUpdate:Date?,_ id:Int64?,_ name:String?,_ facebookPlaceId:String?,_ foursquareId:String?,_ foursquareCategoryIds:String?) {
        let context = getContext()
        
        // Create and store MovesPlace object
        let movesPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "MovesPlaceSegment", in: context)!
        let movesPlaceSegment = NSManagedObject(entity: movesPlaceSegmentEntity, insertInto: context)
        movesPlaceSegment.setValue(startTime, forKey: "startTime")
        movesPlaceSegment.setValue(endTime, forKey: "endTime")
        movesPlaceSegment.setValue(type, forKey: "type")
        movesPlaceSegment.setValue(lat, forKey: "lat")
        movesPlaceSegment.setValue(lon, forKey: "lon")
        movesPlaceSegment.setValue(lastUpdate, forKey: "lastUpdate")
        movesPlaceSegment.setValue(id, forKey: "id")
        movesPlaceSegment.setValue(name, forKey: "name")
        movesPlaceSegment.setValue(facebookPlaceId, forKey: "facebookPlaceId")
        movesPlaceSegment.setValue(foursquareId, forKey: "foursquareId")
        movesPlaceSegment.setValue(foursquareCategoryIds, forKey: "foursquareCategoryIds")

        // Create and store TAPlaceSegment object. If we have a duplicate, overwrite it.
        if(containsObject("TAPlaceSegment",startTime)) {
            deleteObject("TAPlaceSegment",startTime)
        }
        let taPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "TAPlaceSegment", in: context)!
        let taPlaceSegment = NSManagedObject(entity: taPlaceSegmentEntity, insertInto: context)
        taPlaceSegment.setValue(startTime, forKey:"movesStartTime")
        taPlaceSegment.setValue(startTime, forKey:"startTime")
        taPlaceSegment.setValue(endTime, forKey: "endTime")
        taPlaceSegment.setValue(lat, forKey: "lat")
        taPlaceSegment.setValue(lon, forKey: "lon")
        taPlaceSegment.setValue(name, forKey: "name")
        saveContext()
    }

    func containsObject(_ entityName:String, _ startTime:Date) -> Bool {
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

    func deleteObject(_ entityName:String, _ startTime:Date) {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let pred = NSPredicate(format: "startTime == %@", argumentArray: [startTime])
        fr.predicate = pred
        do {
            let result = try context.fetch(fr)
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        } catch {
            fatalError("Unable to access persistent data")
        }
        saveContext()
    }

    func deleteAllDataFor(_ entities:[String]) {
        let context = getContext()
        let persistentStoreCoordinator = getPersistentStoreCoordinator()
        
        for entity in entities {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fr)
            
            do {
                try persistentStoreCoordinator.execute(deleteRequest, with: context)
            } catch {
                fatalError("Unable to delete saved data")
            }
            saveContext()
        }
    }

    
    func parseAndSaveMovesData(_ stories:[AnyObject]) {
        
        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        
        for story in stories {
            if let segments = story[TANetClient.MovesApi.JSONResponseKeys.Segments] as? [AnyObject] {
                for segment in segments {
                    // TODO: Don't force unwrap optionals here
                    let type = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.SegmentType] as! String
                    let startTime = dateFormatter.date(from: segment[TANetClient.MovesApi.JSONResponseKeys.Segment.StartTime] as! String)!
                    let endTime = dateFormatter.date(from: segment[TANetClient.MovesApi.JSONResponseKeys.Segment.EndTime] as! String)!
                    var lastUpdate:Date? = nil
                    if let optionalLastUpdate = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.LastUpdate] as? String{
                        lastUpdate = dateFormatter.date(from: optionalLastUpdate)
                    }
                    
                    switch type {
                    case TANetClient.MovesApi.JSONResponseValues.Segment.Move:
                        createMovesMoveObject(startTime, endTime, lastUpdate)
                    case TANetClient.MovesApi.JSONResponseValues.Segment.Place:
                        // TODO: Don't force unwrap optionals below
                        let place = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.Place] as! [String:AnyObject]
                        let id = place[TANetClient.MovesApi.JSONResponseKeys.Place.Id] as? Int64
                        let name = place[TANetClient.MovesApi.JSONResponseKeys.Place.Name] as? String
                        let type = place[TANetClient.MovesApi.JSONResponseKeys.Place.PlaceType] as! String
                        let facebookPlaceId = place[TANetClient.MovesApi.JSONResponseKeys.Place.FacebookPlaceId] as? String
                        let foursquareId = place[TANetClient.MovesApi.JSONResponseKeys.Place.FoursquareId] as? String
                        var foursquareCategoryIds:String?
                        if let optionalFoursquareCategoryIds = place[TANetClient.MovesApi.JSONResponseKeys.Place.FoursquareCategoryIds] as? [String] {
                            foursquareCategoryIds = String()
                            for fourSquareCategoryId in optionalFoursquareCategoryIds {
                                foursquareCategoryIds?.append(fourSquareCategoryId + ",")
                            }
                        }
                        let coordinates = place[TANetClient.MovesApi.JSONResponseKeys.Place.Location] as! [String:Double]
                        let lat = coordinates[TANetClient.MovesApi.JSONResponseKeys.Place.Latitude]!
                        let lon = coordinates[TANetClient.MovesApi.JSONResponseKeys.Place.Longitude]!
                        
                        createMovesPlaceObject(startTime, endTime, type, lat, lon, lastUpdate, id, name, facebookPlaceId, foursquareId, foursquareCategoryIds)
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
                TANetClient.sharedInstance().movesAccessTokenExpiration = accessTokenExpiration
                TANetClient.sharedInstance().movesAccessToken = UserDefaults.standard.value(forKey: "movesAccessToken") as? String
                TANetClient.sharedInstance().movesAuthCode = UserDefaults.standard.value(forKey: "movesAuthCode") as? String
                TANetClient.sharedInstance().movesRefreshToken = UserDefaults.standard.value(forKey: "movesRefreshToken") as? String
                TANetClient.sharedInstance().movesUserId = UserDefaults.standard.value(forKey: "movesUserId") as? UInt64
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
    
    class func sharedInstance() -> TAModel {
        struct Singleton {
            static var sharedInstance = TAModel()
        }
        return Singleton.sharedInstance
    }
}
