//
//  TALocationTableViewController.swift
//  Time Analytics
//
//  Displays all Time Analytics Place data (TAPlaceSegment managed objects) and allows user to tap into a detail view for each one.
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
        // Set tableview for superclass before calling super method so that it can setup the table's properties (style, etc.)
        super.tableView = placeTableView
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
        
        // If no data, let the user know
        if fetchedResultsController?.sections?.count == 0 {
            createTableEmptyMessageIn(tableView, "No places recorded yet.\n\nIf Moves is tracking information\nit will be displayed here soon.")
        } else {
            removeTableEmptyMessageFrom(tableView)
            // Deselect row if we selected one that caused a segue
            if let selectedRowIndexPath = placeTableView.indexPathForSelectedRow {
                placeTableView.deselectRow(at: selectedRowIndexPath, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let place = fetchedResultsController!.object(at: indexPath) as! TAPlaceSegment
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceTableViewCell", for: indexPath) as! TAPlaceTableViewCell
        
        // Get descriptions and assign to cell labels
        let start = place.startTime! as Date
        let end = place.endTime! as Date
        
        cell.timeInOutLabel.text = generateTimeInOutStringWithDate(start, end)
        cell.lengthLabel.text = generateLengthString(start, end)
        cell.locationLabel.text = place.name!

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = fetchedResultsController?.object(at: indexPath) as! TAPlaceSegment

        showPlaceDetailViewController(place)
    }
}
