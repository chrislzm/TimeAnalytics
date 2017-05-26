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
    
    let viewTitle = "Places"
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        // First set tableview for superclass before calling super method
        tableView = placeTableView
        super.viewDidLoad()
        navigationItem.title = viewTitle

        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Deselect row if we selected one that caused a segue
        if let selectedRowIndexPath = placeTableView.indexPathForSelectedRow {
            placeTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This method must be implemented by our subclass. There's no way
        // CoreDataTableViewController can know what type of cell we want to
        // use.
        
        // Find the right notebook for this indexpath
        let place = fetchedResultsController!.object(at: indexPath) as! TAPlaceSegment
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceTableViewCell", for: indexPath) as! TAPlaceTableViewCell
        
        // Generate descriptions and assign to cell
        
        // Get descriptions and assign to cell labels
        let start = place.startTime! as Date
        let end = place.endTime! as Date
        
        cell.timeInOutLabel.text = generateTimeInOutStringWithDate(start, end)
        cell.lengthLabel.text = generateLengthString(start, end)
        cell.locationLabel.text = place.name!
                 
        // Save data in cell for detail view
        cell.lat = place.lat
        cell.lon = place.lon
        cell.name = place.name!
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = fetchedResultsController?.object(at: indexPath) as! TAPlaceSegment

        showPlaceDetailViewController(place)
    }
}
