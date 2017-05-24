//
//  TAControllerExtensions.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

extension UIViewController {
    
    // MARK: Managed Object Description Strings
    // TODO: Consider moving these methods to TADetailViewController

    func generatePlaceStringDescriptions(_ place:TAPlaceSegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = place.startTime! as Date
        let endTime = place.endTime! as Date

        return generatePlaceStringDescriptionsFromTuple(startTime,endTime,currentYear)
    }
    
    func generatePlaceStringDescriptionsFromTuple(_ startTime:Date,_ endTime:Date,_ currentYear:String?) -> (String,String,String) {
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let lengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateString(startTime,currentYear)
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
        let dateString = generateLongDateString(startTime,currentYear)
        
        return (timeInOutString,commuteLengthString,dateString)
    }
    
    func generateActivityStringDescriptions(_ activity:TAActivitySegment,_ currentYear:String?) -> (String,String,String) {
        let startTime = activity.startTime! as Date
        let endTime = activity.endTime! as Date
        
        let timeInOutString = generateTimeInOutString(startTime,endTime)
        let activityLengthString = generateLengthString(startTime,endTime)
        let dateString = generateLongDateString(startTime,currentYear)
        
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
    
    func generateLengthString(_ startTime:Date,_ endTime:Date) -> String {
        let seconds = Int(endTime.timeIntervalSince(startTime))
        let length = StopWatch(totalSeconds: seconds)
        let lengthString = length.simpleTimeString
        return lengthString
    }
    
    func generateLongDateString(_ time:Date,_ currentYear:String?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d ''yy"
        var dateString = formatter.string(from: time)
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

    // MARK - Data and App Methods
    
    // Returns the core data stack
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    func getHealthStore() -> HKHealthStore {
        let delegate =  UIApplication.shared.delegate as! AppDelegate
        return delegate.healthStore
    }
    
    // MARK - View Methods
    
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
    
    func showPlaceDetailViewController(_ place:TAPlaceSegment) {

        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceDetailViewController") as! TAPlaceDetailViewController
        
        detailController.lat = place.lat
        detailController.lon = place.lon
        if let name = place.name {
            detailController.name = name
        } else {
            detailController.name = "Unknown"
        }

        navigationController!.pushViewController(detailController, animated: true)
    }
    
    func showCommuteDetailViewController(_ commute:TACommuteSegment) {

        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TACommuteDetailViewController") as! TACommuteDetailViewController
        
        if let name = commute.startName {
            detailController.startName = name
        } else {
            detailController.startName = "Unknown"
        }
        if let name = commute.endName {
            detailController.endName = name
        } else {
            detailController.endName = "Unknown"
        }
        
        detailController.startLat = commute.startLat
        detailController.startLon = commute.startLon
        detailController.startTime = commute.startTime! as Date
        detailController.endLat = commute.endLat
        detailController.endLon = commute.endLon
        detailController.endTime = commute.endTime! as Date

        navigationController!.pushViewController(detailController, animated: true)
    }
    
    func showActivityDetailViewController(_ activity:TAActivitySegment) {
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAActivityDetailViewController") as! TAActivityDetailViewController
        
        detailController.name = activity.name
        detailController.type = activity.type
        
        navigationController!.pushViewController(detailController, animated: true)
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
    
    // Remove a progress view and its observers
    func removeProgressView(completionHandler: @escaping ()-> Void) {
        if let progressView = view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                NotificationCenter.default.removeObserver(self)
                let stack = self.getCoreDataStack()
                stack.save()
                completionHandler()
            }
        }
    }
}
