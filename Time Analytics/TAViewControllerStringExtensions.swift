//
//  TAViewControllerStringExtensions.swift
//  Time Analytics
//
//  String description generators for TA managed object data.
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
        let dayTimeIn = Calendar.current.component(.day, from: startTime)
        let dayTimeOut = Calendar.current.component(.day, from: endTime)
        let today = Calendar.current.component(.day, from: Date())
        let yesterday = Calendar.current.component(.day, from: Date(timeInterval: -86400, since: Date())) // 86400 seconds in one day
        var timeOut:String
        
        if dayTimeIn == dayTimeOut {
            timeOut = formatter.string(from: endTime)
        } else if dayTimeOut == today {
            timeOut = "Today"
        } else if dayTimeOut == yesterday {
            timeOut = "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            timeOut = formatter.string(from: endTime)
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
        let formatter = DateFormatter()
        var dateString:String
        
        let dayTimeIn = Calendar.current.component(.day, from: startTime)
        let dayTimeOut = Calendar.current.component(.day, from: endTime)
        
        if dayTimeIn != dayTimeOut {
            formatter.dateFormat = "MMM d"
            dateString = formatter.string(from: startTime)
            formatter.dateFormat = "MMM d ''yy"
            let timeOut = formatter.string(from: endTime)
            dateString.append("-\(timeOut)")
        } else {
            formatter.dateFormat = "E, MMM d ''yy"
            dateString = formatter.string(from: startTime)
        }
        
        if let year = currentYear {
            dateString = removeYearIfSame(dateString,year,-4)
        }
        return dateString
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
