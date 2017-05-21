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
        saveContext()
    }
    
    func createNewTAPlaceObject(_ movesStartTime:NSDate, _ startTime:NSDate, _ endTime:NSDate, _ lat:Double, _ lon:Double, _ name:String?) {
        let context = getContext()
        
        if(containsObject("TAPlaceSegment","startTime",startTime)) {
            deleteObject("TAPlaceSegment","startTime",startTime)
        }
        let taPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "TAPlaceSegment", in: context)!
        let taPlaceSegment = NSManagedObject(entity: taPlaceSegmentEntity, insertInto: context)
        taPlaceSegment.setValue(movesStartTime, forKey:"movesStartTime")
        taPlaceSegment.setValue(startTime, forKey:"startTime")
        taPlaceSegment.setValue(endTime, forKey: "endTime")
        taPlaceSegment.setValue(lat, forKey: "lat")
        taPlaceSegment.setValue(lon, forKey: "lon")
        taPlaceSegment.setValue(name, forKey: "name")
        saveContext()
    }
    
    func generateTAPlaceObjects() {
        
        // Retrieve all moves place segments
        let movesPlaceSegments = getAllMovesPlaceSegments()
        
        for movesPlaceSegment in movesPlaceSegments {
            let movesStartTime = movesPlaceSegment.startTime!
            let movesEndTime = movesPlaceSegment.endTime!
            let lat = movesPlaceSegment.lat
            let lon = movesPlaceSegment.lon
            let name = movesPlaceSegment.name
            
            // Now, find the actual start and end times of this place segment
            var actualStartTime = getLastMoveEndTimeBefore(movesStartTime)
            let actualEndTime = getFirstMoveStartTimeAfter(movesEndTime)
        
            // Get the last place before this one, if any
            if let lastPlace = getLastTAPlaceBefore(movesStartTime) {
                // If the last place was the same as the current place
                if (lastPlace.lat == lat && lastPlace.lon == lon) {
                    // Update the start time
                    actualStartTime = lastPlace.startTime!
                    // Delete the old object
                    deleteObject("TAPlaceSegment", "movesStartTime", lastPlace.movesStartTime!)
                }
            }
            createNewTAPlaceObject(movesStartTime, actualStartTime, actualEndTime, lat, lon, name)
        }
    }
    
    func getLastTAPlaceBefore(_ time:NSDate) -> TAPlaceSegment? {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        let pred = NSPredicate(format: "startTime <= %@", argumentArray: [time])
        fr.predicate = pred
        let sort = NSSortDescriptor(key: "startTime", ascending: false)
        fr.sortDescriptors = [sort]
        var result:[TAPlaceSegment]
        do {
            result = try context.fetch(fr) as! [TAPlaceSegment]
        } catch {
            fatalError("Unable to access persistent data")
        }
        var lastTAPlace:TAPlaceSegment? = nil
        if result.count > 0 {
            lastTAPlace = result[0] as TAPlaceSegment
        }
        return lastTAPlace
    }
    
    func getAllMovesPlaceSegments() -> [MovesPlaceSegment] {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesPlaceSegment")
        let sort = NSSortDescriptor(key: "startTime", ascending: true)
        fr.sortDescriptors = [sort]
        var result:[MovesPlaceSegment]
        do {
            result = try context.fetch(fr) as! [MovesPlaceSegment]
        } catch {
            fatalError("Unable to access persistent data")
        }
        return result
    }
    
    func getLastMoveEndTimeBefore(_ time:NSDate) -> NSDate {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesMoveSegment")
        let pred = NSPredicate(format: "endTime <= %@", argumentArray: [time])
        fr.predicate = pred
        let sort = NSSortDescriptor(key: "endTime", ascending: false)
        fr.sortDescriptors = [sort]
        var result:[MovesMoveSegment]
        do {
            result = try context.fetch(fr) as! [MovesMoveSegment]
        } catch {
            fatalError("Unable to access persistent data")
        }
        if result.count > 0 {
            return result[0].endTime!
        } else {
            return time
        }
    }
    
    func getFirstMoveStartTimeAfter(_ time:NSDate) -> NSDate {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesMoveSegment")
        let pred = NSPredicate(format: "startTime >= %@", argumentArray: [time])
        fr.predicate = pred
        let sort = NSSortDescriptor(key: "startTime", ascending: true)
        fr.sortDescriptors = [sort]
        var result:[MovesMoveSegment]
        do {
            result = try context.fetch(fr) as! [MovesMoveSegment]
        } catch {
            fatalError("Unable to access persistent data")
        }
        if result.count > 0 {
            return result[0].startTime!
        } else {
            return time
        }
    }

    func containsObject(_ entityName:String,_ attributeName:String, _ value:Any) -> Bool {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let pred = NSPredicate(format: "\(attributeName) == %@", argumentArray: [value])
        fr.predicate = pred
        var numResults = 0
        do {
            let result = try context.fetch(fr)
            numResults = result.count
        } catch {
            fatalError("Unable to access persistent data")
        }
        return numResults > 0
    }

    func deleteObject(_ entityName:String,_ attributeName:String, _ value:Any) {
        let context = getContext()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let pred = NSPredicate(format: "\(attributeName) == %@", argumentArray: [value])
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

    func downloadAndProcessAllMovesData(_ completionHandler: @escaping (_ error: String?) -> Void) {
        
        // Downloads all moves data for the user from the beginning of time
        
        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        var beginDate = dateFormatter.date(from: TANetClient.sharedInstance().movesUserFirstDate!)!
        let today = Date()
        // For every set of 30 days from the first user date to present
        while (beginDate < today) {
            
            var endDate = Calendar.current.date(byAdding: .day, value: 30, to: beginDate)!
            if (endDate > today) {
                endDate = today
            }
            
            TANetClient.sharedInstance().getMovesDataFrom(beginDate, endDate){ (monthData, error) in
                guard error == nil else {
                    completionHandler(error!)
                    return
                }
                DispatchQueue.main.async {
                    self.parseAndSaveMovesData(monthData!)
                }
            }
            beginDate = endDate
        }
    }
    
    func downloadAndProcessMovesDataInRange(_ startDate:Date, _ endDate: Date, completionHandler: @escaping (_ error: String?) -> Void) {
        
        // Try getting moves data
        TANetClient.sharedInstance().getMovesDataFrom(startDate, endDate) { (result,error) in
            
            guard error == nil else {
                completionHandler(error!)
                return
            }
            
            self.parseAndSaveMovesData(result!)
            
            completionHandler(nil)
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
                    // TODO: Don't force unwrap optionals here; we should try to process as much data as possible, and return error if we had any problems
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
                        // TODO: Don't force unwrap optionals below. See comment above
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
        
        // Generate our interpolated TAPlace data
        generateTAPlaceObjects()
        
        // Delete the moves data since we don't need it anymore
        deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment"])
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
                TANetClient.sharedInstance().movesUserFirstDate = UserDefaults.standard.value(forKey: "movesUserFirstDate") as? String
            }
        }
        
    }
    
    func saveMovesLoginInfo(_ authCode:String, _ userId:UInt64, _ accessToken:String,_ accessTokenExpiration:Date,_ refreshToken:String, _ userFirstDate:String) {
        UserDefaults.standard.set(authCode, forKey: "movesAuthCode")
        UserDefaults.standard.set(userId, forKey: "movesUserId")
        UserDefaults.standard.set(accessToken, forKey: "movesAccessToken")
        UserDefaults.standard.set(accessTokenExpiration, forKey: "movesAccessTokenExpiration")
        UserDefaults.standard.set(refreshToken, forKey: "movesRefreshToken")
        UserDefaults.standard.set(userFirstDate, forKey: "movesUserFirstDate")
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
