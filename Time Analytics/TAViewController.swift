//
//  TAControllerExtensions.swift
//  Time Analytics
//
//  Implements core methods used in all Time Analytics views controllers.
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

class TAViewController: UIViewController {
    
    // MARK: Generate Description Strings for Managed Objects

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
        let yesterday = Calendar.current.component(.day, from: Date(timeInterval: -86400, since: Date()))
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
    
    // MARK - Data Methods
    
    // Returns the core data stack
    func getCoreDataStack() -> CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    func getHealthStore() -> HKHealthStore {
        let delegate =  UIApplication.shared.delegate as! AppDelegate
        return delegate.healthStore
    }
    
    func saveAllDataToPersistentStore() {
        let stack = self.getCoreDataStack()
        stack.save()
    }
    
    // We delete all data on the background context since objects are loaded in there. On save, deletions will bubble their through all contexts and to the persistent store.
    func clearAllData() {
        let stack = self.getCoreDataStack()
        stack.performBackgroundBatchOperation() { (context) in                TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment","TACommuteSegment","TAActivitySegment"],context)
        }
    }
    
    // MARK - View Methods
    
    // Creates sets up overlay attributes, hides it, and adds it to the view hierarchy. Currently only used for Progress Views (TAProgressView)
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
    
    // Remove a progress view and its observers
    func removeProgressView(completionHandler: (()-> Void)?) {
        if let progressView = view.viewWithTag(100) as? TAProgressView {
            progressView.progressView.setProgress(1.0, animated: true)
            progressView.fadeOut() { (finished) in
                progressView.removeFromObservers()
                progressView.removeFromSuperview()
                if let closure = completionHandler {
                    closure()
                }
            }
        }
    }
    
    // Creates a message that appears in the middle of a tableview, used to notify the user when no data is found
    func createTableEmptyMessageIn(_ table:UITableView, _ message:String) {
        let tableEmptyMessage = UILabel(frame: table.frame)
        tableEmptyMessage.text = message
        tableEmptyMessage.numberOfLines = 10
        tableEmptyMessage.font = UIFont.systemFont(ofSize: 13)
        tableEmptyMessage.textAlignment = .center
        tableEmptyMessage.backgroundColor = UIColor.white
        table.backgroundView = tableEmptyMessage
    }
    
    func removeTableEmptyMessageFrom(_ table: UITableView) {
        table.backgroundView = nil
    }
    
    // MARK: Segue Methods
    
    func showPlaceDetailViewController(_ place:TAPlaceSegment) {

        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceDetailViewController") as! TAPlaceDetailViewController
        
        detailController.lat = place.lat
        detailController.lon = place.lon
        detailController.name = place.name!
        detailController.startTime = place.startTime!
        detailController.endTime = place.endTime!

        navigationController!.pushViewController(detailController, animated: true)
    }
    
    func showCommuteDetailViewController(_ commute:TACommuteSegment) {

        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TACommuteDetailViewController") as! TACommuteDetailViewController
        
        detailController.startName = commute.startName!
        detailController.endName = commute.endName!
        
        detailController.startLat = commute.startLat
        detailController.startLon = commute.startLon
        detailController.startTime = commute.startTime
        detailController.endLat = commute.endLat
        detailController.endLon = commute.endLon
        detailController.endTime = commute.endTime

        navigationController!.pushViewController(detailController, animated: true)
    }
    
    func showActivityDetailViewController(_ activity:TAActivitySegment) {
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAActivityDetailViewController") as! TAActivityDetailViewController
        
        detailController.name = activity.name
        detailController.type = activity.type
        detailController.startTime = activity.startTime
        detailController.endTime = activity.endTime
        
        navigationController!.pushViewController(detailController, animated: true)
    }
}
