//
//  TAControllerExtensions.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // MARK: Managed Object Description Strings
    // TODO: Consider moving this method somewhere closer to the table view controllers that use it

    func generatePlaceStringDescriptions(_ place:TAPlaceSegment) -> (String,String,String,String) {
        let startTime = place.startTime! as Date
        let endTime = place.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let lengthString = generateLengthString(startTime,endTime)
        let nameString = generatePlaceNameString(place.name)
        let dateString = generateDateString(startTime)
        return (timeInOutString,lengthString,nameString,dateString)
    }

    func generateCommuteStringDescriptions(_ commute:TACommuteSegment) -> (String,String,String,String,String) {
        let startTime = commute.startTime! as Date
        let endTime = commute.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let commuteLengthString = generateLengthString(startTime,endTime)
        let startNameString = generatePlaceNameString(commute.startName)
        let endNameString = "to " + generatePlaceNameString(commute.endName)
        let dateString = generateDateString(startTime)
        
        return (timeInOutString,commuteLengthString,startNameString,endNameString,dateString)
    }
    
    func generateTimeInOutString(_ startTime:Date, _ endTime:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeIn = formatter.string(from: startTime)
        let timeOut = formatter.string(from: endTime)
        let timeInOutString = timeIn + " - " + timeOut
        return timeInOutString
    }
    
    func generateLengthString(_ startTime:Date,_ endTime:Date) -> String {
        let seconds = Int(endTime.timeIntervalSince(startTime))
        let length = StopWatch(totalSeconds: seconds)
        let lengthString = length.simpleTimeString
        return lengthString
    }
    
    func generateDateString(_ time:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        let dateString = formatter.string(from: time)
        return dateString
    }
    
    func generatePlaceNameString(_ placeName:String?) -> String {
        let nameString:String
        if let name = placeName {
            nameString = name
        } else {
            nameString = "Unknown"
        }
        return nameString
    }
    
    // Returns the core data stack
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // Creates sets up overlay attributes, hides it, and adds it to the navigation controller view hierarchy
    func setupOverlayView(_ view:UIView, _ parent:UIView) {
        
        if view is TAProgressView {
            (view as! TAProgressView).setupDefaultProperties()
        }
        
        view.alpha = 0
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = 100

        parent.addSubview(view)
        
        let horizontalConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        parent.addConstraints([horizontalConstraint,widthConstraint,heightConstraint,bottomConstraint])
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
        
        //simplified to what OP wanted
        var hoursMinutesAndSeconds: (hours: Int, minutes: Int, seconds: Int) {
            return (hours, minutes, seconds)
        }
        var simpleTimeString: String {
            //let hoursText = timeText(from: hours)
            //let minutesText = timeText(from: minutes)
            //let secondsText = timeText(from: seconds)
            //return "\(hoursText):\(minutesText):\(secondsText)"
            if (days > 0) {
                return "\(days)d \(hours)h \(minutes)m"
            } else if (hours > 0) {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
            //return "\(hoursText):\(minutesText)"
        }
        
        private func timeText(from number: Int) -> String {
            return number < 10 ? "0\(number)" : "\(number)"
        }
    }
}
