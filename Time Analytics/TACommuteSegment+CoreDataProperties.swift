//
//  TACommuteSegment+CoreDataProperties.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData


extension TACommuteSegment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TACommuteSegment> {
        return NSFetchRequest<TACommuteSegment>(entityName: "TACommuteSegment")
    }

    @NSManaged public var endLat: Double
    @NSManaged public var endLon: Double
    @NSManaged public var endName: String?
    @NSManaged public var endTime: NSDate?
    @NSManaged public var startLat: Double
    @NSManaged public var startLon: Double
    @NSManaged public var startName: String?
    @NSManaged public var startTime: NSDate?

}
