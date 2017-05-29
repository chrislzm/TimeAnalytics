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
        let dateString = generateLongDateString(startTime,endTime,currentYear)
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
        let dateString = generateLongDateString(startTime,endTime,currentYear)
        
        return (timeInOutString,commuteLengthString,dateString)
    }
    
    func generateActivityStringDescriptions(_ activity:TAActivitySegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = activity.startTime! as Date
        let endTime = activity.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let activityLengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateString(startTime,endTime,currentYear)
        
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
        let timeIn = formatter.string(from: startTime)
        let (dayStart,dayEnd,dayToday,dayYesterday) = getDayNums(startTime, endTime)
        var timeOut:String
        
        if dayStart == dayEnd {
            timeOut = formatter.string(from: endTime)
        } else {
            timeOut = generateMonthAndDayBasedOn(endTime, dayEnd, dayToday, dayYesterday)
        }
        
        let timeInOutString = timeIn + " - " + timeOut
        return timeInOutString
    }
    
    func generateLengthString(_ startTime:Date,_ endTime:Date) -> String {
        let seconds = Int(endTime.timeIntervalSince(startTime))
        let length = StopWatch(totalSeconds: seconds)
        let lengthString = length.simpleTimeString
        return lengthString
    }
    
    func generateLongDateString(_ startTime:Date,_ endTime:Date,_ currentYear:String?) -> String {

        // Compute day-of-month values for startTime, endTime, today and yesterday to determine the text we generate
        let (dayStart, dayEnd, dayToday, dayYesterday) = getDayNums(startTime,endTime)

        // Start day string
        var dateString = generateMonthAndDayBasedOn(startTime,dayStart,dayToday,dayYesterday)
        
        // End day string
        if dayEnd != dayStart {
            let dayEndString = generateMonthAndDayBasedOn(endTime,dayEnd,dayToday,dayYesterday)
            dateString = "\(dateString)-\(dayEndString)"
        }

        // Add year string if it's not this year
        if let thisYear = currentYear, let yearString = returnYearIfDifferent(endTime,thisYear) {
            dateString = "\(dateString) ''\(yearString)"
        }

        return dateString
    }
    
    // Compares a date's year with a given two digit year, returns nil if they're the same, returns the date's year if they're different
    func returnYearIfDifferent(_ date:Date,_ thisYear:String) -> String? {
        var yearString:String?
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"
        let dateYearString = formatter.string(from: date)
        if dateYearString != thisYear {
            yearString = dateYearString
        }
        return yearString
    }
    
    func generateMonthAndDayBasedOn(_ date:Date,_ dayDate:Int,_ dayToday:Int,_ dayYesterday:Int) -> String {
        
        var dateString:String
        
        if dayDate == dayToday {
            dateString = "Today"
        } else if dayDate == dayYesterday {
            dateString = "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            dateString = formatter.string(from: date)
        }
        return dateString
    }
    
    func getDayNums(_ startTime:Date,_ endTime:Date) -> (Int,Int,Int,Int) {
        let dayStart = Calendar.current.component(.day, from: startTime)
        let dayEnd = Calendar.current.component(.day, from: endTime)
        let dayToday = Calendar.current.component(.day, from: Date())
        let dayYesterday = Calendar.current.component(.day, from: Date(timeInterval: -86400, since: Date())) // 86400 seconds in one day
        return (dayStart,dayEnd,dayToday,dayYesterday)
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
