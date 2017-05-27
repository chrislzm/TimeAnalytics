//
//  Model.swift
//  Time Analytics
//
//  Convenience interface to the Time Analytics model. Used by Controllers and the App Delegate.
//    -Abstracts the Network Client (TANetClient) from the controllers
//    -Manages Moves data download and processing
//    -Manages Time Analytics data generation and TAPlace and Commute Segment entities
//    -Provides general use core data methods
//    -Send updates on data processing via notifications
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import Foundation
import UIKit

class TAModel {
    
    // MARK: Moves Login Methods
    
    func isLoggedIn() -> Bool {
        if let _ = TANetClient.sharedInstance().movesLastChecked {
            return true
        }
        return false
    }
    
    func loadMovesSessionData() {
        // See first if we have ever successfully logged and received data (we could have crashed in the middle of previous login)
        if let lastCheck = UserDefaults.standard.value(forKey: "movesLastChecked") as? Date {
            // Load the remaining session information into our Net Client
            TANetClient.sharedInstance().movesAccessTokenExpiration = UserDefaults.standard.value(forKey: "movesAccessTokenExpiration") as? Date
            TANetClient.sharedInstance().movesAccessToken = UserDefaults.standard.value(forKey: "movesAccessToken") as? String
            TANetClient.sharedInstance().movesAuthCode = UserDefaults.standard.value(forKey: "movesAuthCode") as? String
            TANetClient.sharedInstance().movesRefreshToken = UserDefaults.standard.value(forKey: "movesRefreshToken") as? String
            TANetClient.sharedInstance().movesUserId = UserDefaults.standard.value(forKey: "movesUserId") as? UInt64
            TANetClient.sharedInstance().movesUserFirstDate = UserDefaults.standard.value(forKey: "movesUserFirstDate") as? String
            TANetClient.sharedInstance().movesLatestUpdate = UserDefaults.standard.value(forKey: "movesLatestUpdate") as? Date
            TANetClient.sharedInstance().movesLastChecked = lastCheck
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
    
    func deleteMovesSessionInfo() {
        UserDefaults.standard.removeObject(forKey: "movesAuthCode")
        UserDefaults.standard.removeObject(forKey: "movesUserId")
        UserDefaults.standard.removeObject(forKey: "movesAccessToken")
        UserDefaults.standard.removeObject(forKey: "movesAccessTokenExpiration")
        UserDefaults.standard.removeObject(forKey: "movesRefreshToken")
        UserDefaults.standard.removeObject(forKey: "movesUserFirstDate")
        UserDefaults.standard.removeObject(forKey: "movesLatestUpdate")
        UserDefaults.standard.removeObject(forKey: "movesLastChecked")
        UserDefaults.standard.synchronize()
        TANetClient.sharedInstance().movesAccessTokenExpiration = nil
        TANetClient.sharedInstance().movesAccessToken = nil
        TANetClient.sharedInstance().movesAuthCode = nil
        TANetClient.sharedInstance().movesRefreshToken = nil
        TANetClient.sharedInstance().movesUserId = nil
        TANetClient.sharedInstance().movesUserFirstDate = nil
        TANetClient.sharedInstance().movesLatestUpdate = nil
        TANetClient.sharedInstance().movesLastChecked = nil
    }
    
    // MARK: Moves Data Methods
    
    func createMovesMoveSegment(_ date:Date, _ startTime:Date, _ endTime:Date, _ lastUpdate:Date?, _ context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MovesMoveSegment", in: context)!
        let movesMoveSegment = NSManagedObject(entity: entity, insertInto: context)
        movesMoveSegment.setValue(date, forKey:"date")
        movesMoveSegment.setValue(startTime, forKey: "startTime")
        movesMoveSegment.setValue(endTime, forKey: "endTime")
        movesMoveSegment.setValue(lastUpdate, forKey: "lastUpdate")
        save(context)
    }
    
    func createMovesPlaceSegment(_ date:Date, _ startTime:Date, _ endTime:Date, _ type:String,_ lat:Double,_ lon:Double,  _ lastUpdate:Date?,_ id:Int64?,_ name:String?,_ facebookPlaceId:String?,_ foursquareId:String?,_ foursquareCategoryIds:String?, _ context:NSManagedObjectContext) {

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
        let result = getCoreDataManagedObject("MovesPlaceSegment", "startTime", true, nil, nil, nil, context) as! [MovesPlaceSegment]
        return result
    }
    
    func getMovesPlaceSegmentsBetween(_ startDate:NSDate,_ endDate:NSDate,_ context:NSManagedObjectContext) -> [MovesPlaceSegment] {
        let result = getCoreDataManagedObject("MovesPlaceSegment", "startTime", true, "(date >= %@) AND (date <= %@)", [startDate,endDate], nil, context) as! [MovesPlaceSegment]
        return result
    }
    
    func getLastMoveEndTimeBefore(_ time:NSDate,_ context:NSManagedObjectContext) -> NSDate {
        let result = getCoreDataManagedObject("MovesMoveSegment", "endTime", false, "endTime <= %@", [time], 1, context) as! [MovesMoveSegment]
        if result.count > 0 {
            return result[0].endTime!
        } else {
            return time
        }
    }
    
    func getFirstMoveStartTimeAfter(_ time:NSDate, _ context:NSManagedObjectContext) -> NSDate {
        let result = getCoreDataManagedObject("MovesMoveSegment", "startTime", true, "startTime >= %@", [time], 1, context) as! [MovesMoveSegment]
        if result.count > 0 {
            return result[0].startTime!
        } else {
            return time
        }
    }
    
    // MARK: Moves Data Processing Methods
    
    func autoUpdateMovesData(_ delayInMinutes : Int) {
        
        if delayInMinutes > 0 {
            
            if isLoggedIn() {
                self.downloadAndProcessNewMovesData()
            }
            
            let delayInNanoSeconds = UInt64(delayInMinutes * 60) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.global(qos: .background).asyncAfter(deadline: time) {
                self.autoUpdateMovesData(delayInMinutes)
            }
        }
    }
    
    func downloadAndProcessNewMovesData() {
        
        let stack = getCoreDataStack()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set begin date
        var beginDate:Date!
        var updatedSince:Date?
        
        // If we have previously received data
        if let lastUpdate = TANetClient.sharedInstance().movesLatestUpdate {
            // Add a time buffer window to data request (in case that data has been updated by Moves)
            beginDate = lastUpdate.addingTimeInterval(TANetClient.MovesApi.Constants.UpdateWindowBuffer)
            // Parameter in the API request
            updatedSince = lastUpdate
        } else {
            // Otherwise this is our first login, get all data from the beginning of user's account
            dateFormatter.dateFormat = "yyyyMMdd"
            beginDate = dateFormatter.date(from: TANetClient.sharedInstance().movesUserFirstDate!)!
        }
        
        let today = Date()
        
        let calendar = NSCalendar.current

        let totalDays = (calendar.dateComponents([.day], from: calendar.startOfDay(for: beginDate), to: calendar.startOfDay(for: today))).day! + 1

        // Calculate chunks of data to download/process so that the AppDelegate knows when the download has completed (and can handoff to TA data generators)
        var dataChunks:Int = totalDays / TANetClient.MovesApi.Constants.MaxDaysPerRequest
        dataChunks += totalDays % TANetClient.MovesApi.Constants.MaxDaysPerRequest > 0 ? 1 : 0
        
        while (beginDate < today) {
            
            // Get MaxDaysPerRequest days' data at a time, but don't go past today
            var endDate = Calendar.current.date(byAdding: .day, value: TANetClient.MovesApi.Constants.MaxDaysPerRequest, to: beginDate)!
            if (endDate > today) {
                endDate = today
            }
            
            // Tell the TA Network Client to get the data
            TANetClient.sharedInstance().getMovesDataFrom(beginDate, endDate, updatedSince){ (dataChunk, error) in
                
                guard error == nil else {
                    self.notifyDownloadDataError()
                    return
                }

                // Received the data -- now parse it into Moves segment managed objects
                stack.performBackgroundBatchOperation() { (context) in
                    self.parseAndSaveMovesData(dataChunk!, context)
                    stack.save()
                }
            }
            beginDate = endDate
        }
        
        // The above will return quickly -- let AppDelegate know we've made all the download requests
        notifyWillDownloadData(dataChunks: dataChunks)
    }
    
    // Converts JSON data received from Moves API into MovesPlaceSegment and MovesMoveSegment managed objects
    
    func parseAndSaveMovesData(_ stories:[AnyObject], _ context:NSManagedObjectContext) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // For each "story" in the received storyline data
        for story in stories {
            
            dateFormatter.dateFormat = "yyyyMMdd"
            
            guard let storyDate = story[TANetClient.MovesApi.JSONResponseKeys.Date] as? String, let date = dateFormatter.date(from: storyDate) else {
                notifyDataParsingError()
                return
            }
            
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
            
            if let segments = story[TANetClient.MovesApi.JSONResponseKeys.Segments] as? [AnyObject] {
                for segment in segments {
                    
                    guard let type = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.SegmentType] as? String, let startTimeString = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.StartTime] as? String, let endTimeString = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.EndTime] as? String  else {
                        notifyDataParsingError()
                        return
                    }
                    
                    let startTime = dateFormatter.date(from: startTimeString)!
                    let endTime = dateFormatter.date(from: endTimeString)!
                    
                    var lastUpdate:Date? = nil
                    
                    if let optionalLastUpdate = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.LastUpdate] as? String{
                        lastUpdate = dateFormatter.date(from: optionalLastUpdate)
                    }
                    
                    switch type {
                        
                    case TANetClient.MovesApi.JSONResponseValues.Segment.Move:
                        createMovesMoveSegment(date, startTime, endTime, lastUpdate, context)
                        
                    case TANetClient.MovesApi.JSONResponseValues.Segment.Place:
                        
                        guard let place = segment[TANetClient.MovesApi.JSONResponseKeys.Segment.Place] as? [String:AnyObject], let coordinates = place[TANetClient.MovesApi.JSONResponseKeys.Place.Location] as? [String:Double], let lat = coordinates[TANetClient.MovesApi.JSONResponseKeys.Place.Latitude], let lon = coordinates[TANetClient.MovesApi.JSONResponseKeys.Place.Longitude]  else {
                            notifyDataParsingError()
                            return
                        }
                        
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

                        createMovesPlaceSegment(date,startTime, endTime, type, lat, lon, lastUpdate, id, name, facebookPlaceId, foursquareId, foursquareCategoryIds, context)
                    default:
                        break
                    }
                }
            }
        }
       notifyDidProcessDataChunk()
    }
    
    // After all data has been received, we call this method to find the newest "latestUpdate" value from Moves data, and update our stored value with a newer value if necessary
    
    func saveNewMovesLastUpdateDate(_ context:NSManagedObjectContext) {
        // Search stored MovesMoveSegment objects
        let moveResults = getCoreDataManagedObject("MovesMoveSegment", "lastUpdate", false, nil, nil, 1, context) as! [MovesMoveSegment]
        var movesMoveLastUpdate:Date = Date(timeIntervalSince1970: 0)
        if !moveResults.isEmpty {
            movesMoveLastUpdate = moveResults.first!.lastUpdate! as Date
        }
        // Search stored MovesPlaceSegment objects
        let placeResults = getCoreDataManagedObject("MovesPlaceSegment", "lastUpdate", false, nil, nil, 1, context) as! [MovesPlaceSegment]
        var movesPlaceLastUpdate:Date = Date(timeIntervalSince1970: 0)
        if !placeResults.isEmpty {
            movesPlaceLastUpdate = placeResults.first!.lastUpdate! as Date
        }
        let latestUpdate = movesMoveLastUpdate > movesPlaceLastUpdate ? movesMoveLastUpdate : movesPlaceLastUpdate

        // If we don't have any saved latestUpdate value, or it's older than the newest one received, then update it
        let savedLatestUpdate = UserDefaults.standard.value(forKey: "movesLatestUpdate") as? Date
        if (savedLatestUpdate != nil && latestUpdate > savedLatestUpdate!) || savedLatestUpdate == nil {
            UserDefaults.standard.set(latestUpdate, forKey: "movesLatestUpdate")
            TANetClient.sharedInstance().movesLatestUpdate = latestUpdate
        }
    }
    
    // Updates our local variable that stores the last time we checked Moves for new data
    
    func updateMovesLastChecked() {
        let lastChecked = Date()
        UserDefaults.standard.set(lastChecked, forKey: "movesLastChecked")
        UserDefaults.standard.synchronize()
        TANetClient.sharedInstance().movesLastChecked = lastChecked
    }

    // MARK: Time Analytics Data Creation and Editing Methods
    
    // Creates the "TAPlaceSegment" managed object -- the Time Analytics representation of a MovesPlaceSegment
    
    func createNewTAPlaceSegment(_ movesStartTime:NSDate, _ startTime:NSDate, _ endTime:NSDate, _ lat:Double, _ lon:Double, _ name:String?,_ context:NSManagedObjectContext) {

        if(containsObjectWhere("TAPlaceSegment","startTime",equals: startTime,context)) {
            deleteObjectWhere("TAPlaceSegment","startTime",equals: startTime,context)
        }
        let taPlaceSegmentEntity = NSEntityDescription.entity(forEntityName: "TAPlaceSegment", in: context)!
        let taPlaceSegment = NSManagedObject(entity: taPlaceSegmentEntity, insertInto: context)
        taPlaceSegment.setValue(movesStartTime, forKey:"movesStartTime")
        taPlaceSegment.setValue(startTime, forKey:"startTime")
        taPlaceSegment.setValue(endTime, forKey: "endTime")
        taPlaceSegment.setValue(lat, forKey: "lat")
        taPlaceSegment.setValue(lon, forKey: "lon")
        if let placeName = name {
            taPlaceSegment.setValue(placeName, forKey: "name")
        } else {
            taPlaceSegment.setValue("Unknown", forKey: "name")
        }
        save(context)
    }
    
    // Creates the "TACommuteSegment" object -- the Time Analytics representation of a MovesMoveSegment
    
    func createNewTACommuteSegment(_ startTime:NSDate, _ endTime:NSDate,_ startLat:Double, _ startLon:Double, _ endLat:Double, _ endLon:Double,_ startName:String?,_ endName:String?,_ context:NSManagedObjectContext) {
        if(containsObjectWhere("TACommuteSegment","startTime",equals: startTime,context)) {
            deleteObjectWhere("TACommuteSegment","startTime",equals: startTime,context)
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
    
    // Renames all occurences of a place (based on Lat/Lon) in TA Places, Activities and Commutes Segments
    
    func renamePlaceInAllTAData(_ lat:Double, _ lon:Double, _ newName:String) {
        let stack = getCoreDataStack()
        let context = stack.context
        
        // Update place segments
        let places = getCoreDataManagedObject("TAPlaceSegment", nil, nil, "lat == %@ AND lon == %@", [lat,lon], nil, context) as! [TAPlaceSegment]
        for place in places {
            place.setValue(newName, forKey: "name")
            save(context)
        }
        
        // Update commute segments starting from this place
        let departure = getCoreDataManagedObject("TACommuteSegment", nil, nil, "(startLat == %@ AND startLon == %@)", [lat,lon], nil, context) as! [TACommuteSegment]
        for commute in departure {
            commute.setValue(newName, forKey: "startName")
            save(context)
        }
        
        // Update commute segments ending at this place
        let destination = getCoreDataManagedObject("TACommuteSegment", nil, nil, "(endLat == %@ AND endLon == %@)", [lat,lon], nil, context) as! [TACommuteSegment]
        for commute in destination {
            commute.setValue(newName, forKey: "endName")
            save(context)
        }
        
        // Update activity segments
        let activities = getCoreDataManagedObject("TAActivitySegment", nil, nil, "(placeLat == %@ AND placeLon == %@)", [lat,lon], nil, context) as! [TAActivitySegment]
        for activity in activities {
            activity.setValue(newName, forKey: "placeName")
            save(context)
        }
        
        stack.save()
    }

    // MARK: Time Analytics Object Search and Retrieval Methods
    
    func getTAPlace(_ startTime:Date?, _ lat:Double, _ lon:Double,_ context:NSManagedObjectContext) -> TAPlaceSegment? {
        var query = "lat == %@ AND lon == %@"
        var args = [lat,lon] as [Any]
        if let startTime = startTime {
            query = "\(query) AND startTime == %@"
            args.append(startTime)
        }
        let result = getCoreDataManagedObject("TAPlaceSegment", "startTime", true, query, args, 1,context) as! [TAPlaceSegment]
        if result.count == 0 {
            return nil
        } else {
            return result.first
        }
    }
    
    func getAllTAPlaceSegments(_ context:NSManagedObjectContext) -> [TAPlaceSegment] {
        let result = getCoreDataManagedObject("TAPlaceSegment", "startTime", true, nil, nil, nil, context) as! [TAPlaceSegment]
        return result
    }
    
    func getLastTAPlaceBefore(_ time:NSDate,_ context:NSManagedObjectContext) -> TAPlaceSegment? {
        let result = getCoreDataManagedObject("TAPlaceSegment", "startTime", false, "startTime <= %@", [time], 1, context) as! [TAPlaceSegment]
        var lastTAPlace:TAPlaceSegment? = nil
        if result.count > 0 {
            lastTAPlace = result[0] as TAPlaceSegment
        }
        return lastTAPlace
    }
    
    func getLastTAActivityBefore(_ time:NSDate,_ context:NSManagedObjectContext) -> TAActivitySegment? {
        let result = getCoreDataManagedObject("TAActivitySegment", "startTime", false, "startTime <= %@", [time], 1, context) as! [TAActivitySegment]
        var lastTAActivity:TAActivitySegment? = nil
        if result.count > 0 {
            lastTAActivity = result[0] as TAActivitySegment
        }
        return lastTAActivity
    }
    
    func getTAPlaceThatContains(_ startTime:Date,_ endTime:Date,_ context:NSManagedObjectContext) -> TAPlaceSegment? {
        var result:TAPlaceSegment? = nil
        
        if let place = getLastTAPlaceBefore(startTime as NSDate, context) {
            let placeEndTime = place.endTime! as Date
            if endTime <= placeEndTime {
                result = place
            }
        }
        return result
    }
    
    // MARK: Time Analytics Data Processing Methods
    
    // Manages generation of TAPlaceSegment and TACommuteSegment objects. Automatically called by AppDelegate after it has detected we have successfully downloaded and processed all Moves data chunks into MovesMoveSegment and MovesPlaceSegments objects. Now we need to generate Time Analytics data from those objects.
    
    func generateTADataFromMovesData() {
        let stack = getCoreDataStack()
        let context = stack.context
        var dataChunks = 0
        
        // Calculate approxmimate chunks of data that we need to process here, for notification purposes
        // Because Moves data is dirty we will be discarding a lot of it, so the actual number will be less than or equal to this number
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesPlaceSegment")
        dataChunks += try! context.count(for: fr)
        dataChunks *= 2 // We are going to take maximum two passes
        
        if dataChunks > 0 {
            notifyWillGenerateTAData(dataChunks: dataChunks)
            stack.performBackgroundBatchOperation() { (context) in
                self.generateTAPlaceSegments(context)
                self.generateTACommuteSegments(context)
                stack.save()
                self.saveNewMovesLastUpdateDate(context)
                self.deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment"], context) // We no longer need old moves data, clear it out
                stack.save()
                self.notifyWillCompleteUpdate()
            }
        } else {
            notifyWillCompleteUpdate()
        }
    }
    
    // Generates Time Analytics TAPlaceSegment managed objects from Moves data
    
    func generateTAPlaceSegments(_ context:NSManagedObjectContext) {

        // Retrieve all moves place segments
        let movesPlaceSegments = getAllMovesPlaceSegments(context)
        
        for movesPlaceSegment in movesPlaceSegments {
            let movesStartTime = movesPlaceSegment.startTime!
            let movesEndTime = movesPlaceSegment.endTime!
            let lat = movesPlaceSegment.lat
            let lon = movesPlaceSegment.lon
            var name = movesPlaceSegment.name
            
            // If we already have a TAPlace recorded at this location, then use the existing name
            if let existingTAPlace = getTAPlace(nil, lat, lon, context) {
                name = existingTAPlace.name!
            }
            
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
                    deleteObjectWhere("TAPlaceSegment", "movesStartTime", equals: lastPlace.movesStartTime!,context)
                }
            }
            createNewTAPlaceSegment(movesStartTime, actualStartTime, actualEndTime, lat, lon, name, context)
            
            notifyDidProcessDataChunk()
        }
    }

    // Generates Time Analytics TACommuteSegment managed objects based on the TAPlaceSegments we generated in the previous step
    
    func generateTACommuteSegments(_ context:NSManagedObjectContext) {
        
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
                createNewTACommuteSegment(startTime, endTime, startLat, startLon, endLat, endLon, startName, endName, context)
                
                // Set last object to current
                lastPlace = thisPlace
                
                notifyDidProcessDataChunk()
            }
        }
    }

    // MARK: General Purpose Core Data Methods
    
    func containsObjectWhere(_ entityName:String,_ attributeName:String,equals:Any, _ context:NSManagedObjectContext) -> Bool {
        let result = getCoreDataManagedObject(entityName, nil, nil, "\(attributeName) == %@", [equals], 1, context)
        return result.count > 0
    }
    
    func deleteObjectWhere(_ entityName:String,_ attributeName:String,equals:Any, _ context:NSManagedObjectContext) {
        let result = getCoreDataManagedObject(entityName, nil, nil, "\(attributeName) == %@", [equals], nil, context)
        for object in result {
            context.delete(object as! NSManagedObject)
        }
        save(context)
    }

    func deleteAllDataFor(_ entities:[String], _ context:NSManagedObjectContext) {
        for entity in entities {
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entity)

            do {
                let items = try context.fetch(fr) as! [NSManagedObject]
                for item in items {
                    context.delete(item)
                }
            } catch {
                fatalError("Unable to delete data")
            }
            save(context)
        }
    }
    
    func getCoreDataManagedObject(_ entityName:String,_ sortDescriptorKey:String?,_ sortAscending:Bool?,_ predFormat:String?,_ argumentArray:[Any]?, _ fetchLimit:Int?,  _ context:NSManagedObjectContext) -> [Any]{
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if let fetchLimit = fetchLimit {
            fr.fetchLimit = fetchLimit
        }
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
    
    // MARK: App Delegate, Notification and Singleton Methods
    
    func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func notifyWillCompleteUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("willCompleteUpdate"), object: nil)
        }
    }

    func notifyDataParsingError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("dataParsingError"), object: nil)
        }
    }
    
    func notifyDownloadDataError() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("downloadDataError"), object: nil)
        }
    }
    
    func notifyWillDownloadData(dataChunks:Int) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("willDownloadData"), object: dataChunks)
        }
    }
    
    func notifyDidProcessDataChunk() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
        }
    }
    
    func notifyWillGenerateTAData(dataChunks:Int) {
        NotificationCenter.default.post(name: Notification.Name("willGenerateTAData"), object: dataChunks)
    }

    class func sharedInstance() -> TAModel {
        struct Singleton {
            static var sharedInstance = TAModel()
        }
        return Singleton.sharedInstance
    }
}
