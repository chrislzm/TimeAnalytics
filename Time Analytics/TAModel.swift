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
    
    // MARK: Moves Login Methods
    
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
    
    func deleteMovesLoginInfo() {
        UserDefaults.standard.removeObject(forKey: "movesAuthCode")
        UserDefaults.standard.removeObject(forKey: "movesUserId")
        UserDefaults.standard.removeObject(forKey: "movesAccessToken")
        UserDefaults.standard.removeObject(forKey: "movesAccessTokenExpiration")
        UserDefaults.standard.removeObject(forKey: "movesRefreshToken")
        UserDefaults.standard.removeObject(forKey: "movesUserFirstDate")
        TANetClient.sharedInstance().movesUserId = nil
        TANetClient.sharedInstance().movesAccessToken = nil
        TANetClient.sharedInstance().movesAccessTokenExpiration = nil
        TANetClient.sharedInstance().movesAuthCode = nil
        TANetClient.sharedInstance().movesRefreshToken = nil
        TANetClient.sharedInstance().movesUserFirstDate = nil
    }
    
    // MARK: Moves Data Methods
    
    func createMovesMoveObject(_ date:Date, _ startTime:Date, _ endTime:Date, _ lastUpdate:Date?, _ context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MovesMoveSegment", in: context)!
        let movesMoveSegment = NSManagedObject(entity: entity, insertInto: context)
        movesMoveSegment.setValue(date, forKey:"date")
        movesMoveSegment.setValue(startTime, forKey: "startTime")
        movesMoveSegment.setValue(endTime, forKey: "endTime")
        movesMoveSegment.setValue(lastUpdate, forKey: "lastUpdate")
        save(context)
    }
    
    func createMovesPlaceObject(_ date:Date, _ startTime:Date, _ endTime:Date, _ type:String,_ lat:Double,_ lon:Double,  _ lastUpdate:Date?,_ id:Int64?,_ name:String?,_ facebookPlaceId:String?,_ foursquareId:String?,_ foursquareCategoryIds:String?, _ context:NSManagedObjectContext) {

        let movesPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "MovesPlaceSegment", in: context)!
        let movesPlaceSegment = NSManagedObject(entity: movesPlaceSegmentEntity, insertInto: context)
        movesPlaceSegment.setValue(date, forKey: "date")
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
        save(context)
    }
    
    func getAllMovesPlaceSegments(_ context:NSManagedObjectContext) -> [MovesPlaceSegment] {
        let result = getCoreDataManagedObject("MovesPlaceSegment", "startTime", true, nil, nil, context) as! [MovesPlaceSegment]
        return result
    }
    
    func getMovesPlaceSegmentsBetween(_ startDate:NSDate,_ endDate:NSDate,_ context:NSManagedObjectContext) -> [MovesPlaceSegment] {
        let result = getCoreDataManagedObject("MovesPlaceSegment", "startTime", true, "(date >= %@) AND (date <= %@)", [startDate,endDate], context) as! [MovesPlaceSegment]
        return result
    }
    
    func getLastMoveEndTimeBefore(_ time:NSDate,_ context:NSManagedObjectContext) -> NSDate {
        let result = getCoreDataManagedObject("MovesMoveSegment", "endTime", false, "endTime <= %@", [time], context) as! [MovesMoveSegment]
        if result.count > 0 {
            return result[0].endTime!
        } else {
            return time
        }
    }
    
    func getFirstMoveStartTimeAfter(_ time:NSDate, _ context:NSManagedObjectContext) -> NSDate {
        let result = getCoreDataManagedObject("MovesMoveSegment", "startTime", true, "startTime >= %@", [time], context) as! [MovesMoveSegment]
        if result.count > 0 {
            return result[0].startTime!
        } else {
            return time
        }
    }
    
    // MARK: Moves Data Processing Methods
    
    func downloadAndProcessAllMovesData(_ completionHandler: @escaping (_ dataChunks:Int, _ error: String?) -> Void) {
        
        let stack = getCoreDataStack()
        
        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        var beginDate = dateFormatter.date(from: TANetClient.sharedInstance().movesUserFirstDate!)!
        let today = Date()
        
        let calendar = NSCalendar.current
        // TODO: This calculation may or may not be accurate
        let totalDays = (calendar.dateComponents([.day], from: calendar.startOfDay(for: beginDate), to: calendar.startOfDay(for: today))).day! + 1
        
        var dataChunks:Int = totalDays / TANetClient.MovesApi.Constants.MaxDaysPerRequest
        dataChunks += totalDays % TANetClient.MovesApi.Constants.MaxDaysPerRequest > 0 ? 1 : 0
        
        while (beginDate < today) {
            
            var endDate = Calendar.current.date(byAdding: .day, value: TANetClient.MovesApi.Constants.MaxDaysPerRequest, to: beginDate)!
            if (endDate > today) {
                endDate = today
            }
            
            TANetClient.sharedInstance().getMovesDataFrom(beginDate, endDate){ (dataChunk, error) in
                
                guard error == nil else {
                    completionHandler(0,error!)
                    return
                }
                
                stack.performBackgroundBatchOperation() { (context) in
                    self.parseAndSaveMovesData(dataChunk!, context)
                    stack.save()
                }
            }
            beginDate = endDate
        }
        completionHandler(dataChunks,nil)
    }
    
    func downloadAndProcessMovesDataInRange(_ startDate:Date, _ endDate: Date, completionHandler: @escaping (_ error: String?) -> Void) {
        let stack = getCoreDataStack()
        
        // Try getting moves data
        TANetClient.sharedInstance().getMovesDataFrom(startDate, endDate) { (result,error) in
            
            guard error == nil else {
                completionHandler(error!)
                return
            }
            
            stack.performBackgroundBatchOperation() { (context) in
                self.parseAndSaveMovesData(result!, context)
                stack.save()
                completionHandler(nil)
            }
            
        }
    }
    
    func parseAndSaveMovesData(_ stories:[AnyObject], _ context:NSManagedObjectContext) {
        
        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        for story in stories {
            
            dateFormatter.dateFormat = "yyyyMMdd"
            let date = dateFormatter.date(from: story[TANetClient.MovesApi.JSONResponseKeys.Date] as! String)!
            
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
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
                        createMovesMoveObject(date, startTime, endTime, lastUpdate, context)
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
                        createMovesPlaceObject(date,startTime, endTime, type, lat, lon, lastUpdate, id, name, facebookPlaceId, foursquareId, foursquareCategoryIds, context)
                    default:
                        break
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            // Send notification that we completed processing one chunk
            NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
        }
    }
    
    // MARK: Time Analytics Data Methods
    
    func createNewTAActivityObject(_ startTime:NSDate,_ endTime:NSDate,_ name:String,_ context:NSManagedObjectContext) {
        if(containsObject("TAActivitySegment","startTime",startTime,context)) {
            deleteObject("TAActivitySegment","startTime",startTime,context)
        }
        let taActivitySegmentEntity = NSEntityDescription.entity(forEntityName: "TAActivitySegment", in: context)!
        let taActivitySegment = NSManagedObject(entity: taActivitySegmentEntity, insertInto: context)
        taActivitySegment.setValue(startTime, forKey:"startTime")
        taActivitySegment.setValue(endTime, forKey: "endTime")
        taActivitySegment.setValue(name, forKey:"name")
        save(context)
    }
    
    func createNewTAPlaceObject(_ movesStartTime:NSDate, _ startTime:NSDate, _ endTime:NSDate, _ lat:Double, _ lon:Double, _ name:String?,_ context:NSManagedObjectContext) {
        
        if(containsObject("TAPlaceSegment","startTime",startTime,context)) {
            deleteObject("TAPlaceSegment","startTime",startTime,context)
        }
        let taPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "TAPlaceSegment", in: context)!
        let taPlaceSegment = NSManagedObject(entity: taPlaceSegmentEntity, insertInto: context)
        taPlaceSegment.setValue(movesStartTime, forKey:"movesStartTime")
        taPlaceSegment.setValue(startTime, forKey:"startTime")
        taPlaceSegment.setValue(endTime, forKey: "endTime")
        taPlaceSegment.setValue(lat, forKey: "lat")
        taPlaceSegment.setValue(lon, forKey: "lon")
        taPlaceSegment.setValue(name, forKey: "name")
        save(context)
    }
    
    func createNewTACommuteObject(_ startTime:NSDate, _ endTime:NSDate,_ startLat:Double, _ startLon:Double, _ endLat:Double, _ endLon:Double,_ startName:String?,_ endName:String?,_ context:NSManagedObjectContext) {
        if(containsObject("TACommuteSegment","startTime",startTime,context)) {
            deleteObject("TACommuteSegment","startTime",startTime,context)
        }
        let taMoveSegmentEntity = NSEntityDescription.entity(forEntityName: "TACommuteSegment", in: context)!
        let taMoveSegment = NSManagedObject(entity: taMoveSegmentEntity, insertInto: context)
        taMoveSegment.setValue(startTime, forKey:"startTime")
        taMoveSegment.setValue(endTime, forKey: "endTime")
        taMoveSegment.setValue(startLat, forKey: "startLat")
        taMoveSegment.setValue(startLon, forKey: "startLon")
        taMoveSegment.setValue(endLat, forKey: "endLat")
        taMoveSegment.setValue(endLon, forKey: "endLon")
        taMoveSegment.setValue(startName, forKey: "startName")
        taMoveSegment.setValue(endName, forKey: "endName")
        save(context)
    }
    
    func getAllTAPlaceSegments(_ context:NSManagedObjectContext) -> [TAPlaceSegment] {
        let result = getCoreDataManagedObject("TAPlaceSegment", "startTime", true, nil, nil, context) as! [TAPlaceSegment]
        return result
    }
    
    func getLastTAPlaceBefore(_ time:NSDate,_ context:NSManagedObjectContext) -> TAPlaceSegment? {
        let result = getCoreDataManagedObject("TAPlaceSegment", "startTime", false, "startTime <= %@", [time], context) as! [TAPlaceSegment]
        var lastTAPlace:TAPlaceSegment? = nil
        if result.count > 0 {
            lastTAPlace = result[0] as TAPlaceSegment
        }
        return lastTAPlace
    }
    
    // MARK: Time Analytics Data Processing Methods
    
    func generateTADataFromMovesData(_ completionHandler: @escaping (_ totalRecordsToProcess:Int, _ error: String?) -> Void) {
        let stack = getCoreDataStack()
        let context = stack.context
        var dataChunks = 0
        
        // TODO: Replace these forced try statements
        
        // Get total moves place segments we need to process
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesPlaceSegment")
        dataChunks += try! context.count(for: fr)
        dataChunks += dataChunks - 1 // We are going to take about two passes through
        
        stack.performBackgroundBatchOperation() { (context) in
            self.generateTAPlaceObjects(context)
            self.generateTACommuteObject(context)
            DispatchQueue.main.async {
                // Send notification that we completed processing
                NotificationCenter.default.post(name: Notification.Name("didCompleteProcessing"), object: nil)
            }
        }
        
        completionHandler(dataChunks,nil)
    }
    
    func generateTACommuteObject(_ context:NSManagedObjectContext) {
        // Get all of our place objects
        var taPlaceSegments = getAllTAPlaceSegments(context)
        
        // Check first we even have place segments to proces
        if let firstSegment = taPlaceSegments.first {

            var lastPlace = firstSegment
            taPlaceSegments.remove(at: 0)
            
            // For each place object
            for thisPlace in taPlaceSegments {
                
                // Get the info of the last place
                let startLat = lastPlace.lat
                let startLon = lastPlace.lon
                let startTime = lastPlace.endTime!
                let startName = lastPlace.name
                
                // Get the info of the current place
                let endLat = thisPlace.lat
                let endLon = thisPlace.lon
                let endTime = thisPlace.startTime!
                let endName = thisPlace.name
                
                // Create a new commute object with that information
                createNewTACommuteObject(startTime, endTime, startLat, startLon, endLat, endLon, startName, endName, context)
                
                // Set last object to current
                lastPlace = thisPlace
                
                DispatchQueue.main.async {
                    // Send notification that we completed processing one chunk
                    NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
                }
            }
        }
    }

    func generateTAPlaceObjects(_ context:NSManagedObjectContext) {

        // Retrieve all moves place segments
        let movesPlaceSegments = getAllMovesPlaceSegments(context)
        
        for movesPlaceSegment in movesPlaceSegments {
            let movesStartTime = movesPlaceSegment.startTime!
            let movesEndTime = movesPlaceSegment.endTime!
            let lat = movesPlaceSegment.lat
            let lon = movesPlaceSegment.lon
            let name = movesPlaceSegment.name
            
            // Now, find the actual start and end times of this place segment
            var actualStartTime = getLastMoveEndTimeBefore(movesStartTime,context)
            let actualEndTime = getFirstMoveStartTimeAfter(movesEndTime,context)
            
            // Get the last place before this one, if any
            if let lastPlace = getLastTAPlaceBefore(movesStartTime,context) {
                // If the last place was the same as the current place
                if (lastPlace.lat == lat && lastPlace.lon == lon) {
                    // Update the start time
                    actualStartTime = lastPlace.startTime!
                    // Delete the old object
                    deleteObject("TAPlaceSegment", "movesStartTime", lastPlace.movesStartTime!,context)
                }
            }
            createNewTAPlaceObject(movesStartTime, actualStartTime, actualEndTime, lat, lon, name, context)
            
            DispatchQueue.main.async {
                // Send notification that we completed processing one chunk
                NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
            }
        }
    }

    func renamePlaceInAllTAData(_ lat:Double, _ lon:Double, _ newName:String) {
        let stack = getCoreDataStack()
        let context = stack.context
        
        // Update place segments
        let places = getCoreDataManagedObject("TAPlaceSegment", nil, nil, "lat == %@ AND lon == %@", [lat,lon], context) as! [TAPlaceSegment]
        for place in places {
            place.setValue(newName, forKey: "name")
            stack.save()
        }
        
        // Update commute segments starting from this place
        let departure = getCoreDataManagedObject("TACommuteSegment", nil, nil, "(startLat == %@ AND startLon == %@)", [lat,lon,lat,lon], context) as! [TACommuteSegment]
        for commute in departure {
            commute.setValue(newName, forKey: "startName")
            stack.save()
        }
        
        // Update commute segments ending at this place
        let destination = getCoreDataManagedObject("TACommuteSegment", nil, nil, "(endLat == %@ AND endLon == %@)", [lat,lon,lat,lon], context) as! [TACommuteSegment]
        for commute in destination {
            commute.setValue(newName, forKey: "endName")
            stack.save()
        }
    }

    // MARK: Core Data Methods
    
    func containsObject(_ entityName:String,_ attributeName:String, _ value:Any, _ context:NSManagedObjectContext) -> Bool {
        let result = getCoreDataManagedObject(entityName, nil, nil, "\(attributeName) == %@", [value], context)
        return result.count > 0
    }
    
    func deleteObject(_ entityName:String,_ attributeName:String, _ value:Any, _ context:NSManagedObjectContext) {
        let result = getCoreDataManagedObject(entityName, nil, nil, "\(attributeName) == %@", [value], context)
        for object in result {
            context.delete(object as! NSManagedObject)
        }
        save(context)
    }

    func deleteAllDataFor(_ entities:[String]) {
        let stack = getCoreDataStack()
        let context = stack.context
        let persistentStoreCoordinator = stack.coordinator
        
        for entity in entities {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fr)
            
            do {
                try persistentStoreCoordinator.execute(deleteRequest, with: context)
            } catch {
                fatalError("Unable to delete saved data")
            }
        }
    }
    
    func getCoreDataManagedObject(_ entityName:String,_ sortDescriptorKey:String?,_ sortAscending:Bool?,_ predFormat:String?,_ argumentArray:[Any]?,  _ context:NSManagedObjectContext) -> [Any]{
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if let sortKey = sortDescriptorKey, let ascending = sortAscending {
            let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
            fr.sortDescriptors = [sort]
        }
        if let predQuery = predFormat, let arguments = argumentArray {
            let pred = NSPredicate(format: predQuery, argumentArray: arguments)
            fr.predicate = pred
        }
        var result:[Any]
        do {
            result = try context.fetch(fr)
        } catch {
            fatalError("Unable to access persistent data")
        }
        return result
    }
    
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    func save() {
        let stack = getCoreDataStack()
        stack.save()
    }
    
    func save(_ context:NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Error saving data")
        }
    }
    
    // MARK: Helper Functions
    
    func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // MARK: Shared Instance
    
    class func sharedInstance() -> TAModel {
        struct Singleton {
            static var sharedInstance = TAModel()
        }
        return Singleton.sharedInstance
    }
}
