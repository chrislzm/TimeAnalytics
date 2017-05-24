//
//  TAPlaceSegment+CoreDataProperties.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData


extension TAPlaceSegment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TAPlaceSegment> {
        return NSFetchRequest<TAPlaceSegment>(entityName: "TAPlaceSegment")
    }

    @NSManaged public var endTime: NSDate?
    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
    @NSManaged public var movesStartTime: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var startTime: NSDate?

}
