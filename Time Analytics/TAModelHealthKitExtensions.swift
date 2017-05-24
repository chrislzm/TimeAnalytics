//
//  TAModelHealthKitExtensions.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/23/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

extension TAModel {
    
    func importHealthKitData(completionHandler: @escaping (_ dataChunks:Int) -> Void) {
        let stack = getCoreDataStack()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        let fromDate = dateFormatter.date(from: TANetClient.sharedInstance().movesUserFirstDate!)!
        
        // Import Sleep Data
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        retrieveHealthStoreData(sleepType) { (query,result,error) in
            guard error == nil else {
                return
            }
            NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
            stack.performBackgroundBatchOperation() { (context) in
                for item in result! {
                    let sample = item as! HKCategorySample
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        // Create the TAActivity object
                        TAModel.sharedInstance().createNewTAActivityObject(sample.startDate as NSDate, sample.endDate as NSDate, "In Bed", context)
                    }
                }
                stack.save()
                NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
            }
        }

        // Import Workout Data
        let workoutType = HKWorkoutType.workoutType()
        retrieveHealthStoreData(workoutType) { (query,result,error) in
            guard error == nil else {
                return
            }
            NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
            stack.performBackgroundBatchOperation() { (context) in
                for item in result! {
                    let workout = item as! HKWorkout
                    let workoutType = self.getHealthKitWorkoutTypeString(workout.workoutActivityType.rawValue)
                    // Create the TAActivity object
                    DispatchQueue.main.async {
                        TAModel.sharedInstance().createNewTAActivityObject(item.startDate as NSDate, item.endDate as NSDate, workoutType, context)
                    }
                }
                stack.save()
                NotificationCenter.default.post(name: Notification.Name("didProcessDataChunk"), object: nil)
            }
        }

        // Tell the completion handler we have 4 total data chunks to complete
        completionHandler(4)
    }
    
    func getHealthStore() -> HKHealthStore {
        let delegate =  UIApplication.shared.delegate as! AppDelegate
        return delegate.healthStore
    }
    
    func retrieveHealthStoreData(_ type:HKSampleType, completionHandler: @escaping (HKSampleQuery, [HKSample]?, Error?) -> Void) {
        let healthStore = getHealthStore()
        // Use a sortDescriptor to get the recent data first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: completionHandler)
        healthStore.execute(query)
    }
    
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
