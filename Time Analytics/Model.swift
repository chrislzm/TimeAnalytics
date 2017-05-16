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
        let moveObject = NSManagedObject(entity: entity, insertInto: context)
        moveObject.setValue(startTime, forKey: "startTime")
        moveObject.setValue(endTime, forKey: "endTime")
        moveObject.setValue(lastUpdate, forKey: "lastUpdate")
        saveContext()
    }
    
    func createMovesPlaceObject() {
        
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
