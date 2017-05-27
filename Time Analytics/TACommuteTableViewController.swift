//
//  TACommuteTableViewController.swift
//  Time Analytics
//
//  Displays all Time Analytics Commute data (TACommuteSegment managed objects) and allows user to tap into a detail view for each one.
//
//  Created by Chris Leung on 5/21/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import UIKit

class TACommuteTableViewController: TATableViewController {

    @IBOutlet weak var commuteTableView: UITableView!
    
    let viewTitle = "Commutes"

    // MARK: Lifecycle
    override func viewDidLoad() {        
        // Set tableview for superclass before calling super method
        tableView = commuteTableView
        super.viewDidLoad()

        navigationItem.title = viewTitle
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TACommuteSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Deselect row if we selected one that caused a segue
        if let selectedRowIndexPath = commuteTableView.indexPathForSelectedRow {
            commuteTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let commute = fetchedResultsController!.object(at: indexPath) as! TACommuteSegment
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TACommuteTableViewCell", for: indexPath) as! TACommuteTableViewCell

        // Get label values
        let start = commute.startTime! as Date
        let end = commute.endTime! as Date

        // Set label values
        cell.timeLabel.text = generateTimeInOutStringWithDate(start, end)
        cell.lengthLabel.text = generateLengthString(start, end)
        cell.startNameLabel.text = commute.startName!
        cell.endNameLabel.text = commute.endName!
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let commute = fetchedResultsController!.object(at: indexPath) as! TACommuteSegment
        showCommuteDetailViewController(commute)
    }
}
