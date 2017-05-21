//
//  TAPlaceDetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/17/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreData
import Foundation
import MapKit
import UIKit

class TAPlaceDetailViewController: TATableViewController {
    @IBOutlet weak var placeTableView: UITableView!
    @IBOutlet weak var visitHistoryLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var lat:Double! = nil
    var lon:Double! = nil
    var name:String! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = placeTableView
   
        // Set the title
        title = name
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        let pred = NSPredicate(format: "(lat == %@) AND (lon == %@)", argumentArray: [lat,lon])
        fr.predicate = pred
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "startTime", cacheName: nil)
        
        visitHistoryLabel.text = "  Visit History - \(fetchedResultsController!.fetchedObjects!.count) Total"
        
        // Setup Mapview = Add the geocoded location as an annotation to the map
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This method must be implemented by our subclass. There's no way
        // CoreDataTableViewController can know what type of cell we want to
        // use.
        
        // Find the right notebook for this indexpath
        let place = fetchedResultsController!.object(at: indexPath) as! TAPlaceSegment
        
        // Create the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceDetailTableViewCell", for: indexPath) as! TAPlaceDetailTableViewCell
        
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
        
        cell.timeInOutLabel.text = timeIn + " - " + timeOut
        cell.lengthLabel.text = visitTime.simpleTimeString
        
        formatter.dateFormat = "E, MMM d"
        let date = formatter.string(from: startTime)
        
        cell.dateLabel.text = date

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
}
