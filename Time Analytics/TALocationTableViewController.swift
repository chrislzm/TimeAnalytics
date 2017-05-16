//
//  TALocationTableViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import UIKit

class TALocationTableViewController: TATableViewController {
    
    var settingsButton:UIBarButtonItem?
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the title
        title = "Time Analytics - Places"
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "MovesPlace")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Setup and add the Edit button
        settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.plain, target:self, action: #selector(TALocationTableViewController.showSettingsMenu))
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        executeSearch()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This method must be implemented by our subclass. There's no way
        // CoreDataTableViewController can know what type of cell we want to
        // use.
        
        // Find the right notebook for this indexpath
        let place = fetchedResultsController!.object(at: indexPath) as! MovesPlace
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath)
        
        // Sync notebook -> cell
        cell.textLabel?.text = "\(place.startTime): \(place.name) - \(place.lat),\(place.lon)"
        // cell.detailTextLabel?.text = String(format: "%d notes", nb.notes!.count)
        
        return cell
    }
    
    func showSettingsMenu() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "TASettingsView") as! TASettingsViewController
        navigationController?.pushViewController(controller, animated: true)
    }
}
