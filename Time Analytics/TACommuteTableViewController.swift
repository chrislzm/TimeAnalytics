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
    
    let viewTitle = "My Commutes"
    
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

        title = viewTitle
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TACommuteSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBottomNavigationBar()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Find the right notebook for this indexpath
        let commute = fetchedResultsController!.object(at: indexPath) as! TACommuteSegment
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TACommuteTableViewCell", for: indexPath) as! TACommuteTableViewCell

        // Get label values
        let (timeLabelText,commuteLengthLabelText,startNameLabelText,endNameLabelText,_) = generateCommuteStringDescriptions(commute)
        
        // Set label values
        cell.timeLabel.text = timeLabelText
        cell.lengthLabel.text = commuteLengthLabelText
        cell.startNameLabel.text = startNameLabelText
        cell.endNameLabel.text = endNameLabelText
        
        // Store commute information in cell
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
