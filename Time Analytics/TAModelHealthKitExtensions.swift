//
//  TAModelHealthKitExtensions.swift
//  Time Analytics
//
//  Extensions to the Time Analytics Model (TAModel) class for supporting Apple HealthKit data import
//
//  Created by Chris Leung on 5/23/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import HealthKit
import UIKit

extension TAModel {

    // MARK: Constants
    
    struct Constants {
        static let HealthKitDataChunks = 4  // We process HealthKit data in 4 stages
    }

    // MARK: Time Analytics Data Creation Methods
    
    // Creates a "TAActivitySegment" managed object -- the Time Analytics representation of a HealthKit activity
    
    func createNewTAActivitySegment(_ startTime:Date,_ endTime:Date,_ type:String, _ name:String,_ movesFirstTime:Date, _ context:NSManagedObjectContext) {
        
        // Delete existing object if one exists, so we can update/don't have duplicates
        if(containsObjectWhere("TAActivitySegment","startTime",equals: startTime,context)) {
            deleteObjectWhere("TAActivitySegment","startTime",equals: startTime,context)
        }
        let taActivitySegmentEntity = NSEntityDescription.entity(forEntityName: "TAActivitySegment", in: context)!
        let taActivitySegment = NSManagedObject(entity: taActivitySegmentEntity, insertInto: context)
        taActivitySegment.setValue(startTime, forKey:"startTime")
        taActivitySegment.setValue(endTime, forKey: "endTime")
        taActivitySegment.setValue(type, forKey:"type")
        taActivitySegment.setValue(name, forKey:"name")
        
        // If this activity occurs during an existing Place Segment
        if startTime >= movesFirstTime, let place = TAModel.sharedInstance().getTAPlaceThatContains(startTime,endTime, context) {
            // Save this place information into the activity data (since this activity occurs at this place)
            taActivitySegment.setValue(place.startTime,forKey:"placeStartTime")
            taActivitySegment.setValue(place.endTime,forKey:"placeEndTime")
            taActivitySegment.setValue(place.lat,forKey:"placeLat")
            taActivitySegment.setValue(place.lon,forKey:"placeLon")
            taActivitySegment.setValue(place.name,forKey:"placeName")
        }
        save(context)
    }
    
    // Manages the import of HealthKit data to Time Analytics: Reads HealthKit data and creates TAActivity objects for them
    
    func updateHealthKitData() {
        let stack = getCoreDataStack()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        let firstMovesDataDate = dateFormatter.date(from: TANetClient.sharedInstance().movesUserFirstDate!)! as Date
        
        // The date from which we should begin importing
        var fromDate:Date? = nil
        
        // If we have imported data before, then use the startTime of the newest activity as our fromDate
        if let latestActivity = getLastTAActivityBefore(Date() as NSDate,stack.context) {
            fromDate = latestActivity.endTime! as Date
        }
        
        // Retrieve Sleep Data
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        retrieveHealthStoreData(sleepType,fromDate) { (query,result,error) in
            guard error == nil else {
                return
            }
            // Generate TAActivitySegment objects for the data
            stack.performBackgroundBatchOperation() { (context) in
                self.notifyDidProcessDataChunk()
                for item in result! {
                    let sample = item as! HKCategorySample
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        TAModel.sharedInstance().createNewTAActivitySegment(sample.startDate, sample.endDate, "Sleep", "In Bed",firstMovesDataDate, context)
                    }
                }
                stack.save()
                self.notifyDidProcessDataChunk()
            }
        }
        
        // Retrieve Workout Data
        let workoutType = HKWorkoutType.workoutType()
        retrieveHealthStoreData(workoutType,fromDate) { (query,result,error) in
            guard error == nil else {
                return
            }
            stack.performBackgroundBatchOperation() { (context) in
                self.notifyDidProcessDataChunk()
                for item in result! {
                    let workout = item as! HKWorkout
                    let workoutType = self.getHealthKitWorkoutTypeString(workout.workoutActivityType.rawValue)
                    TAModel.sharedInstance().createNewTAActivitySegment(item.startDate, item.endDate, "Workout", workoutType, firstMovesDataDate, context)
                }
                stack.save()
                self.notifyDidProcessDataChunk()
            }
        }
    }
 
    // MARK: HealthKit Store Methods
    
    func getHealthStore() -> HKHealthStore {
        let delegate =  UIApplication.shared.delegate as! AppDelegate
        return delegate.healthStore
    }
    
    // Used to get authorization to the user's Health Store
    
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: Error?) -> Void)!) {
        let healthKitStore = getHealthStore()
        // State the health data type(s) we want to read from HealthKit.
        let readableTypes: Set<HKSampleType> = [HKWorkoutType.workoutType(), HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        
        healthKitStore.requestAuthorization(toShare: nil, read: readableTypes) { (success, error) -> Void in
            if( completion != nil ) {
                completion(success,error)
            }
        }
    }
    
    // General purpose function for retrieving data from the HealthKit "Health Store"
    
    func retrieveHealthStoreData(_ type:HKSampleType,_ fromDate:Date?, completionHandler: @escaping (HKSampleQuery, [HKSample]?, Error?) -> Void) {
        let healthStore = getHealthStore()
        var predicate:NSPredicate! = nil
        if let fromDate = fromDate {
            predicate = HKQuery.predicateForSamples(withStart: fromDate, end: Date(), options: [])
        }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: completionHandler)
        healthStore.execute(query)
    }
    
    // Translate HealthKit enum values for workout types into strings
    
    func getHealthKitWorkoutTypeString(_ activityType:UInt) -> String {
        switch activityType {
        case 1:
            return "American Football"
        case 2:
            return "Archery"
        case 3:
            return "Australian Football"
        case 4:
            return "Badminton"
        case 5:
            return "Baseball"
        case 6:
            return "Basketball"
        case 7:
            return "Bowling"
        case 8:
            return "Boxing"
        case 9:
            return "Climbing"
        case 10:
            return "Cricket"
        case 11:
            return "Cross Training"
        case 12:
            return "Curling"
        case 13:
            return "Cycling"
        case 14:
            return "Dance"
        case 15:
            return "Dance Inspired Training"
        case 16:
            return "Elliptical"
        case 17:
            return "Equestrian Sports"
        case 18:
            return "Fencing"
        case 19:
            return "Fishing"
        case 20:
            return "Functional Strength Training"
        case 21:
            return "Golf"
        case 22:
            return "Gymnastics"
        case 23:
            return "Handball"
        case 24:
            return "Hiking"
        case 25:
            return "Hockey"
        case 26:
            return "Hunting"
        case 27:
            return "Lacrosse"
        case 28:
            return "Martial Arts"
        case 29:
            return "Mind And Body"
        case 30:
            return "Mixed Metabolic Cardio Training"
        case 31:
            return "Paddle Sports"
        case 32:
            return "Play"
        case 33:
            return "Preparation And Recovery"
        case 34:
            return "Racquetball"
        case 35:
            return "Rowing"
        case 36:
            return "Rugby"
        case 37:
            return "Running"
        case 38:
            return "Sailing"
        case 39:
            return "Skating Sports"
        case 40:
            return "SnowSports"
        case 41:
            return "Soccer"
        case 42:
            return "Softball"
        case 43:
            return "Squash"
        case 44:
            return "Stair Climbing"
        case 45:
            return "Surfing Sports"
        case 46:
            return "Swimming"
        case 47:
            return "Table Tennis"
        case 48:
            return "Tennis"
        case 49:
            return "Track And Field"
        case 50:
            return "Traditional Strength Training"
        case 51:
            return "Volleyball"
        case 52:
            return "Walking"
        case 53:
            return "Water Fitness"
        case 54:
            return "Water Polo"
        case 55:
            return "Water Sports"
        case 56:
            return "Wrestling"
        case 57:
            return "Yoga"
        case 58:
            return "Barre"
        case 59:
            return "Core Training"
        case 60:
            return "Cross Country Skiing"
        case 61:
            return "Downhill Skiing"
        case 62:
            return "Flexibility"
        case 63:
            return "High Intensity Interval Training"
        case 64:
            return "Jump Rope"
        case 65:
            return "Kick Boxing"
        case 66:
            return "Pilates"
        case 67:
            return "Snowboarding"
        case 68:
            return "Stairs"
        case 69:
            return "Step Training"
        case 70:
            return "Wheelchair Walk Pace"
        case 71:
            return "Wheelchair Run Pace"
        default:
            return "Other"
        }
    }
}
