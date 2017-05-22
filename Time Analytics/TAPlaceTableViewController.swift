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
    
    var settingsButton:UIBarButtonItem?
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup tableview
        tableView = placeTableView
        tableView.separatorStyle = .none
        
        // Set the title
        title = "Recent Places"
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "daySectionIdentifier", cacheName: nil)
        
        // Setup and add the Edit button
        settingsButton = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.plain, target:self, action: #selector(TAPlaceTableViewController.showSettingsMenu))
        navigationItem.rightBarButtonItem = settingsButton
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle: String?
        if let sectionIdentifier = fetchedResultsController!.sections?[section].name {
            if let numericSection = Int(sectionIdentifier) {
                // Parse the numericSection into its year/month/day components.
                let year = numericSection / 10000
                let month = (numericSection / 100) % 100
                let day = numericSection % 100
                
                // Reconstruct the date from these components.
                var components = DateComponents()
                components.calendar = Calendar.current
                components.day = day
                components.month = month
                components.year = year
                
                // Set the section title with this date
                if let date = components.date {
                    sectionTitle = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
                }
            }
        }
        
        return sectionTitle
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
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
    
    func showSettingsMenu() {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "TASettingsView") as! TASettingsViewController
        navigationController?.pushViewController(controller, animated: true)
    }
 
    func didProcessDataChunk(_ notification:Notification) {
        executeSearch()
        tableView.reloadData()
    }
}
