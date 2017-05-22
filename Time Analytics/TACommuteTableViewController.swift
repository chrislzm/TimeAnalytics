//
//  TACommuteTableViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/21/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import UIKit

class TACommuteTableViewController: TATableViewController {

    @IBOutlet weak var commuteTableView: UITableView!
    
    // MARK: Actions
    func showPlacesButtonPressed() {
        let placesController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceTableViewController") as! TAPlaceTableViewController
        let navigationController = self.navigationController!
        navigationController.setViewControllers([placesController], animated: false)
    }

    // MARK: Lifecycle
    override func viewDidLoad() {        
        // First set tableview for superclass before calling super method
        tableView = commuteTableView
        super.viewDidLoad()

        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TACommuteSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
        
        setupBottomNavigationBar()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Find the right notebook for this indexpath
        let commute = fetchedResultsController!.object(at: indexPath) as! TACommuteSegment
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TACommuteTableViewCell", for: indexPath) as! TACommuteTableViewCell
        
        // Sync notebook -> cell
        let formatter = DateFormatter()
        let startTime = commute.startTime! as Date
        let endTime = commute.endTime! as Date
        formatter.dateFormat = "h:mm a"
        let timeIn = formatter.string(from: startTime)
        var timeOut:String
        timeOut = formatter.string(from: endTime)
        
        let visitSeconds = Int((commute.endTime! as Date).timeIntervalSince(commute.startTime! as Date))
        let visitTime = StopWatch(totalSeconds: visitSeconds)
        
        let startName:String
        let endName:String
        if let name = commute.startName {
            startName = name
        } else {
            startName = "Unknown"
        }
        if let name = commute.endName {
            endName = name
        } else {
            endName = "Unknown"
        }
        
        cell.timeLabel.text = timeIn + " - " + timeOut
        cell.lengthLabel.text = visitTime.simpleTimeString
        cell.startNameLabel.text = startName
        cell.endNameLabel.text = "to \(endName)"
        cell.startName = commute.startName
        cell.startLat = commute.startLat
        cell.startLon = commute.startLon
        cell.endName = commute.startName
        cell.endLat = commute.startLat
        cell.endLon = commute.startLon
        
        return cell
    }
    
    // MARK: Helper functions
    func setupBottomNavigationBar() {
        let showCommutesButton = UIBarButtonItem(title: "Places", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TACommuteTableViewController.showPlacesButtonPressed))
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.setToolbarItems([showCommutesButton], animated: true)
    }
    
    
}
