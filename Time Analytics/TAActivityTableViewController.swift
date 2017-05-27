//
//  TAActivityTableViewController.swift
//  Time Analytics
//
//  Displays all Time Analytics Activity data (TAActivitySegment managed objects) and allows user to tap into a detail view for each one.
//
//  Created by Chris Leung on 5/23/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//


import CoreData
import UIKit

class TAActivityTableViewController: TATableViewController {

    @IBOutlet weak var activityTableView: UITableView!
    
    let viewTitle = "Activities"
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        // Set tableview for superclass before calling super method
        tableView = activityTableView
        super.viewDidLoad()
        
        navigationItem.title = viewTitle
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAActivitySegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Deselect row if we selected one that caused a segue
        if let selectedRowIndexPath = activityTableView.indexPathForSelectedRow {
            activityTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let activity = fetchedResultsController!.object(at: indexPath) as! TAActivitySegment
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TAActivityTableViewCell", for: indexPath) as! TAActivityTableViewCell
        
        // Get label values
        let start = activity.startTime! as Date
        let end = activity.endTime! as Date
        
        // Set label values
        cell.timeLabel.text = generateTimeInOutStringWithDate(start, end)
        cell.lengthLabel.text = generateLengthString(start, end)
        cell.nameLabel.text = "\(activity.type!): \(activity.name!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = fetchedResultsController!.object(at: indexPath) as! TAActivitySegment
        showActivityDetailViewController(activity)
    }
}
