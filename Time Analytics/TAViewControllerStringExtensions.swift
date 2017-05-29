//
//  TAViewControllerStringExtensions.swift
//  Time Analytics
//
//  Extension to the TAViewController class. Implements string description generators for TA managed object data.
//
//  Created by Chris Leung on 5/28/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

extension TAViewController {
    
    func generatePlaceStringDescriptions(_ place:TAPlaceSegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = place.startTime! as Date
        let endTime = place.endTime! as Date
        
        return generatePlaceStringDescriptionsFromTuple(startTime,endTime,currentYear)
    }
    
    func generatePlaceStringDescriptionsFromTuple(_ startTime:Date,_ endTime:Date,_ currentYear:String?) -> (String,String,String) {
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let lengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateRangeString(startTime,endTime,currentYear)
        return (timeInOutString,lengthString,dateString)
    }
    
    func generatePlaceStringDescriptionsShortDateFromTuple(_ startTime:Date,_ endTime:Date,_ currentYear:String?) -> (String,String,String) {
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let lengthString = generateLengthString(startTime,endTime)
        let dateString = generateShortDateString(startTime,currentYear)
        return (timeInOutString,lengthString,dateString)
    }
    
    func generateCommuteStringDescriptions(_ commute:TACommuteSegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = commute.startTime! as Date
        let endTime = commute.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let commuteLengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateRangeString(startTime,endTime,currentYear)
        
        return (timeInOutString,commuteLengthString,dateString)
    }
    
    func generateActivityStringDescriptions(_ activity:TAActivitySegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = activity.startTime! as Date
        let endTime = activity.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let activityLengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateRangeString(startTime,endTime,currentYear)
        
        return (timeInOutString,activityLengthString,dateString)
    }
    
    func generateActivityStringDescriptionsShortDate(_ activity:TAActivitySegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = activity.startTime! as Date
        
        let (timeInOutString,activityLengthString,_) = generateActivityStringDescriptions(activity,nil)
        let dateString = generateShortDateString(startTime,currentYear)
        
        return (timeInOutString,activityLengthString,dateString)
    }
    
    func generateTimeInOutString(_ startTime:Date, _ endTime:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeIn = formatter.string(from: startTime)
        let timeOut = formatter.string(from: endTime)
        let timeInOutString = timeIn + " - " + timeOut
        return timeInOutString
    }
    
    func generateTimeInOutStringWithDate(_ startTime:Date,_ endTime:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTimeString = formatter.string(from: startTime)
        var endTimeString:String
        // If endTime is on same day, just generate the time string again
        if Calendar.current.isDate(startTime, inSameDayAs: endTime) {
            endTimeString = formatter.string(from: endTime)
        } else {
            // They are on different days, so we want to output either the month+day, or a string like "Yesterday", "Today"
            endTimeString = friendlyDate(endTime)
        }

        let timeInOutString = "\(startTimeString) - \(endTimeString)"
        return timeInOutString
    }
    
    func generateLengthString(_ startTime:Date,_ endTime:Date) -> String {
        let seconds = Int(endTime.timeIntervalSince(startTime))
        let length = StopWatch(totalSeconds: seconds)
        let lengthString = length.simpleTimeString
        return lengthString
    }
    
    func generateLongDateRangeString(_ startTime:Date,_ endTime:Date,_ currentYear:String?) -> String {
        let currentTime = Date()
        var dateString:String
        
        // If the two dates are from the same year
        if (Calendar.current.isDate(startTime, equalTo: endTime, toGranularity: .year)) {
            
            // If the dates are from this year
            if Calendar.current.isDate(startTime, equalTo: currentTime, toGranularity: .year) {
                
                // If they're on the same day, just generate one string
                if Calendar.current.isDate(startTime, equalTo: endTime, toGranularity: .day) {
                    dateString = friendlyDate(startTime)
                } else {
                    // Otherwise generate both strings
                    dateString = "\(friendlyDate(startTime))-\(friendlyDate(endTime))"
                }
 
            } else { // Else they're from a year before
                
                // If they're on the same day, just generate one string
                if Calendar.current.isDate(startTime, equalTo: endTime, toGranularity: .day) {
                    dateString = dateWithYear(startTime)
                } else {
                    // Otherwise generate both strings, with year on the second string
                    dateString = "\(dateWithNoYear(startTime))-\(dateWithYear(endTime))"
                }
                
            }
        } else { // The dates are from different years
            dateString = dateWithYear(startTime)

            if (Calendar.current.isDate(endTime, equalTo: currentTime, toGranularity: .year)) {
                dateString = "\(dateString)-\(friendlyDate(endTime))"
            } else {
                dateString = "\(dateString)-\(dateWithYear(endTime))"
            }
        }
        
        return dateString
    }
    
    func dateWithYear(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d ''yy"
        return formatter.string(from: date)
    }
    
    func dateWithNoYear(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Outputs "Today", "Yesterday" or if it isn't either, outputs the month and day
    func friendlyDate(_ date:Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return dateWithNoYear(date)
        }
    }
    
    func generateShortDateString(_ time:Date,_ currentYear:String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        var dateString = formatter.string(from: time)
        if let year = currentYear {
            dateString = removeYearIfSame(dateString,year,-3)
        }
        return dateString
    }
    
    // Removes the year component of a date string if it's the same as the current year
    func removeYearIfSame(_ dateString:String,_ year:String,_ offset:Int) -> String {
        var dateDigits = dateString.characters
        let yearDigit2 = dateDigits.popLast()!
        let yearDigit1 = dateDigits.popLast()!
        var curYearDigits = year.characters
        if yearDigit2 == curYearDigits.popLast()!, yearDigit1 == curYearDigits.popLast()! {
            return dateString.substring(to: dateString.index(dateString.endIndex, offsetBy: offset))
        } else {
            return dateString
        }
    }
    
    // Creates length of time string in days minutes and hours
    struct StopWatch {
        
        var totalSeconds: Int
        
        var years: Int {
            return totalSeconds / 31536000
        }
        
        var days: Int {
            return (totalSeconds % 31536000) / 86400
        }
        
        var hours: Int {
            return (totalSeconds % 86400) / 3600
        }
        
        var minutes: Int {
            return (totalSeconds % 3600) / 60
        }
        
        var seconds: Int {
            return totalSeconds % 60
        }
        
        var simpleTimeString: String {
            if (days > 0) {
                return "\(days)d \(hours)h \(minutes)m"
            } else if (hours > 0) {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
}
