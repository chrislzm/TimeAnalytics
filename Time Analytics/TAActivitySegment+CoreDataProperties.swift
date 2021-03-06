//
//  TAActivitySegment+CoreDataProperties.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData


extension TAActivitySegment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TAActivitySegment> {
        return NSFetchRequest<TAActivitySegment>(entityName: "TAActivitySegment")
    }

    @NSManaged public var endTime: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var placeEndTime: NSDate?
    @NSManaged public var placeLat: Double
    @NSManaged public var placeLon: Double
    @NSManaged public var placeName: String?
    @NSManaged public var placeStartTime: NSDate?
    @NSManaged public var startTime: NSDate?
    @NSManaged public var type: String?

}
