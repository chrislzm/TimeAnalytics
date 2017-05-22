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
    
    let viewTitle = "My Places"
    
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
        title = viewTitle

        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        
        // Generate descriptions and assign to cell
        
        // Get descriptions and assign to cell labels
        let (timeInOutString,lengthString,nameString,_) = generatePlaceStringDescriptions(place)
        cell.timeInOutLabel.text = timeInOutString
        cell.lengthLabel.text = lengthString
        cell.locationLabel.text = nameString
        
        // Save data in cell for detail view
        cell.lat = place.lat
        cell.lon = place.lon
        cell.name = nameString
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Grab the DetailVC from Storyboard
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceDetailViewController") as! TAPlaceDetailViewController
        
        // Populate view controller with data from the selected item
        let place = fetchedResultsController?.object(at: indexPath) as? TAPlaceSegment
        detailController.lat = place?.lat
        detailController.lon = place?.lon
        if let name = place?.name {
            detailController.name = name
        } else {
            detailController.name = "Unknown"
        }
        
        // Present the view controller using navigation
        navigationController!.pushViewController(detailController, animated: true)
    }

    func setupBottomNavigationBar() {
        let showCommutesButton = UIBarButtonItem(title: "Commutes", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TAPlaceTableViewController.showCommutesButtonPressed))
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.setToolbarItems([showCommutesButton], animated: true)
    }
}
