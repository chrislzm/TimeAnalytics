//
//  TACommuteSegment+CoreDataClass.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/21/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import CoreData

@objc(TACommuteSegment)
public class TACommuteSegment: NSManagedObject {
    
    // Transient property for grouping a table into sections based
    // on day of entity's date. Allows an NSFetchedResultsController
    // to sort by date, but also display the day as the section title.
    //   - Constructs a string of format "YYYYMMDD", where YYYY is the year,
    //     MM is the month, and DD is the day (all integers).
    
    public var daySectionIdentifier: String? {
        let currentCalendar = Calendar.current
        self.willAccessValue(forKey: "daySectionIdentifier")
        var sectionIdentifier = ""
        let date = self.startTime! as Date
        let day = currentCalendar.component(.day, from: date)
        let month = currentCalendar.component(.month, from: date)
        let year = currentCalendar.component(.year, from: date)
        
        // Construct integer from year, month, day. Convert to string.
        sectionIdentifier = "\(year * 10000 + month * 100 + day)"
        
        self.didAccessValue(forKey: "daySectionIdentifier")
        
        return sectionIdentifier
    }
    
}
