//
//  TALocationTableViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import Foundation
import UIKit

class TAPlaceTableViewController: TATableViewController {
    
    @IBOutlet weak var placeTableView: UITableView!
    
    // MARK: Actions
    
    func showCommutesButtonPressed() {
        // Grab the DetailVC from Storyboard
        let commutesController = self.storyboard!.instantiateViewController(withIdentifier: "TACommuteTableViewController") as! TACommuteTableViewController
        
        let navigationController = self.navigationController!
        navigationController.setViewControllers([commutesController], animated: false)
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        // First set tableview for superclass before calling super method
        tableView = placeTableView
        super.viewDidLoad()


        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
        
        setupBottomNavigationBar()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This method must be implemented by our subclass. There's no way
        // CoreDataTableViewController can know what type of cell we want to
        // use.
        
        // Find the right notebook for this indexpath
        let place = fetchedResultsController!.object(at: indexPath) as! TAPlaceSegment
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceTableViewCell", for: indexPath) as! TAPlaceTableViewCell
        
        // Sync notebook -> cell
        let formatter = DateFormatter()
        let startTime = place.startTime! as Date
        let endTime = place.endTime! as Date
        formatter.dateFormat = "h:mm a"
        let timeIn = formatter.string(from: startTime)
        var timeOut:String
        let cal = Calendar(identifier: .gregorian)
        let nextDay = cal.startOfDay(for: startTime.addingTimeInterval(86400))
        if endTime > nextDay {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "h:mm a"
        }
        timeOut = formatter.string(from: endTime)
        
        let visitSeconds = Int((place.endTime! as Date).timeIntervalSince(place.startTime! as Date))
        let visitTime = StopWatch(totalSeconds: visitSeconds)
        
        var name:String
        if let _ = place.name {
            name = place.name!
        } else {
            name = "Unknown"
        }

        
        cell.timeInOutLabel.text = timeIn + " - " + timeOut
        cell.lengthLabel.text = visitTime.simpleTimeString
        cell.locationLabel.text = name
        cell.lat = place.lat
        cell.lon = place.lon
        cell.name = place.name
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Grab the DetailVC from Storyboard
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceDetailViewController") as! TAPlaceDetailViewController
        
        // Populate view controller with data from the selected item
        let place = fetchedResultsController?.object(at: indexPath) as? TAPlaceSegment
        detailController.lat = place?.lat
        detailController.lon = place?.lon
        detailController.name = place?.name
        
        // Present the view controller using navigation
        navigationController!.pushViewController(detailController, animated: true)
    }

    func setupBottomNavigationBar() {
        let showCommutesButton = UIBarButtonItem(title: "Commutes", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TAPlaceTableViewController.showCommutesButtonPressed))
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.setToolbarItems([showCommutesButton], animated: true)
    }
}
