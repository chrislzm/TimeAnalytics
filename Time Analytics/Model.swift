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

class Model {
    func createMovesMoveObject(_ startTime:Date, _ endTime:Date, _ lastUpdate:Date?) {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "MovesMove", in: context)!
        let move = NSManagedObject(entity: entity, insertInto: context)
        move.setValue(startTime, forKey: "startTime")
        move.setValue(endTime, forKey: "endTime")
        move.setValue(lastUpdate, forKey: "lastUpdate")
        saveContext()
    }
    
    func createMovesPlaceObject(_ startTime:Date, _ endTime:Date, _ type:String,_ lat:Double,_ lon:Double,  _ lastUpdate:Date?,_ id:Int64?,_ name:String?,_ facebookPlaceId:String?, foursquareId:String?, foursquareCategoryIds:String?) {
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
    
    // MARK: Helper Functions
    
    func getContext() -> NSManagedObjectContext {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.persistentContainer.viewContext
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
