//
//  TAControllerExtensions.swift
//  Time Analytics
//
//  This is the foundational "UIViewController" for all Time Analytics View Controllers, implementing core methods that are used throughout the application.
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import HealthKit
import UIKit

class TAViewController: UIViewController {
    
    let ProgressViewDefaultTag = 100 // For identifying and removing progress views
        
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
        let stack = getCoreDataStack()
        stack.save()
    }
    
    // We delete all data on the background context since objects are loaded in there. On save, deletions will bubble their through all contexts and to the persistent store.
    func clearAllData() {
        let stack = getCoreDataStack()
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
        view.tag = ProgressViewDefaultTag
        
        parent.addSubview(view)
        
        let horizontalConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: parent, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        parent.addConstraints([horizontalConstraint,widthConstraint,heightConstraint,bottomConstraint])
    }
    
    // Remove a progress view and its observers
    func removeProgressView(completionHandler: (()-> Void)?) {
        if let progressView = view.viewWithTag(ProgressViewDefaultTag) as? TAProgressView {
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
    
    func displayErrorAlert(_ error:String?,_ completionHandler: ((UIAlertAction) -> Void)?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: error, message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: completionHandler))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Segue Methods
    
    func showPlaceDetailViewController(_ place:TAPlaceSegment) {

        let detailController = storyboard!.instantiateViewController(withIdentifier: "TAPlaceDetailViewController") as! TAPlaceDetailViewController
        
        detailController.lat = place.lat
        detailController.lon = place.lon
        detailController.name = place.name!
        detailController.startTime = place.startTime!
        detailController.endTime = place.endTime!

        navigationController!.pushViewController(detailController, animated: true)
    }
    
    func showCommuteDetailViewController(_ commute:TACommuteSegment) {

        let detailController = storyboard!.instantiateViewController(withIdentifier: "TACommuteDetailViewController") as! TACommuteDetailViewController
        
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
        let detailController = storyboard!.instantiateViewController(withIdentifier: "TAActivityDetailViewController") as! TAActivityDetailViewController
        
        detailController.name = activity.name
        detailController.type = activity.type
        detailController.startTime = activity.startTime
        detailController.endTime = activity.endTime
        
        navigationController!.pushViewController(detailController, animated: true)
    }
}
