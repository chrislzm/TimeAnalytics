//
//  TAActivityDetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/23/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreLocation
import MapKit
import UIKit

class TAActivityDetailViewController: TADetailViewController {
    var type:String?
    var name:String?
    var activityHistoryTableData = [TAActivitySegment]()
    
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var pastMonthLabel: UILabel!
    @IBOutlet weak var averageTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var activityHistoryTableHeaderLabel: UILabel!
    @IBOutlet weak var activityHistoryTableView: UITableView!
    
    @IBOutlet weak var activityPlacesTableHeaderLabel: UILabel!
    @IBOutlet weak var placeHistoryTableView: UITableView!
    
    override func viewDidLoad() {
        
        // Setup the view
        setTitle()
        
        // Setup Data Sources
        activityHistoryTableData = getEntityObjectsWithQuery("TAActivitySegment", "name == %@ AND type == %@", [name!,type!], "startTime", false) as! [TAActivitySegment]
        
        //timeBeforeDepartingTableData = getDeparturePlaceHistory(commuteHistoryTableData)
        //timeAfterArrivingTableData = getDestinationPlaceHistory(commuteHistoryTableData)

        // Get data for this place, to be used below
        let(activityDates,activityLengths,totalActivities,totalActivityTime) = getDataForThisActivity()
        
        setupLineChartView(lineChartView, activityDates, activityLengths)
        setupMapView()
        /*
        // SETUP SUMMARY LABELS
        
        totalCommutesLabel.text = "\(totalCommutes)"
        
        let lastMonthCommutes = getNumLastMonthCommutes()
        pastMonthTotalCommutesLabel.text = "\(lastMonthCommutes)"
        
        let averageCommuteTimeString = (StopWatch(totalSeconds: Int(totalCommuteTime)/totalCommutes)).simpleTimeString
        averageTimeLabel.text = averageCommuteTimeString
        
        let totalCommuteTimeString = (StopWatch(totalSeconds: Int(totalCommuteTime))).simpleTimeString
        totalTimeLabel.text = totalCommuteTimeString
        */
        // SETUP TABLEVIEWS
        
        // Styles
        activityHistoryTableView.separatorStyle = .none
        activityHistoryTableView.allowsSelection = false
        
        // SETUP TABLE HEADER LABELS
        
        //setCommuteHistoryTableHeaderLabelText(totalCommutes)
        //setTimeBeforeDepartingTableHeaderLabel()
        //setTimeAfterArrivingTableHeaderLabel()
    }
    
    // MARK: Table Data Source Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == activityHistoryTableView {
            count = activityHistoryTableData.count
        }
        
        return count!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if tableView == activityHistoryTableView {
            // Find the right notebook for this indexpath
            let activity = activityHistoryTableData[indexPath.row]
            
            // Create the cell
            let activityCell = tableView.dequeueReusableCell(withIdentifier: "TAActivityDetailActivityTableViewCell", for: indexPath) as! TAActivityDetailActivityTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateActivityStringDescriptions(activity)
            activityCell.timeLabel.text = timeInOutString
            activityCell.lengthLabel.text = lengthString
            activityCell.dateLabel.text = dateString
            cell = activityCell
        }
        
        return cell
    }
    
    // MARK: Data Methods
    
    func getDataForThisActivity() -> ([Double],[Double],Int,Double) {
        let activities = getEntityObjectsWithQuery("TAActivitySegment", "type == %@ AND name == %@", [type!,name!], "startTime", true) as! [TAActivitySegment]
        let totalActivities = activities.count
        var totalActivityTime:Double = 0
        var activityLengths = [Double]()
        var activityDates = [Double]()
        for activity in activities {
            let startTime = activity.startTime! as Date
            let endTime = activity.endTime! as Date
            let activityTime = endTime.timeIntervalSince(startTime)
            totalActivityTime += activityTime
            activityLengths.append(activityTime)
            activityDates.append(startTime.timeIntervalSinceReferenceDate)
        }
        return (activityDates,activityLengths,totalActivities,totalActivityTime)
    }
    
    // MARK: View Methods
    
    func setTitle() {
        title = "\(name!)"
    }
    
    func setupMapView() {
        
        class TACoordinate {
            let lat:Double
            let lon:Double
            
            init(latitude:Double,longitude:Double) {
                lat = latitude
                lon = longitude
            }
            
            func inArray(_ inTACoordinates:[TACoordinate]) -> Bool {
                for coordinate in inTACoordinates {
                    if coordinate.lat == lat, coordinate.lon == lon {
                        return true
                    }
                }
                return false
            }
        }
        
        var activityCoordinates = [TACoordinate]()
        
        // Put unique coordinates into a set
        for activity in activityHistoryTableData {
            if activity.placeLat != 0, activity.placeLon != 0 {
                let coordinate = TACoordinate(latitude: activity.placeLat, longitude: activity.placeLon)
                if !coordinate.inArray(activityCoordinates) {
                    activityCoordinates.append(coordinate)
                    print("Inserted Lat: \(activity.placeLat) Lon: \(activity.placeLon)")
                }
            }
        }
        print("Set: \(activityCoordinates)")
        // Add coordinates to the map as annotations
        for activity in activityCoordinates {
            let coordinate = CLLocationCoordinate2D(latitude: activity.lat, longitude: activity.lon)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
        
        // If we have a coordinate, then get the min/max of all coordinates, used to center the view
        if let activityCoordinate = activityCoordinates.first {
            
            // Setup variables for loop
            var maxLat = activityCoordinate.lat
            var minLat = activityCoordinate.lat
            var maxLon = activityCoordinate.lon
            var minLon = activityCoordinate.lon
            
            for activity in activityCoordinates {
                if activity.lat > maxLat {
                    maxLat = activity.lat
                }
                if activity.lat < minLat {
                    minLat = activity.lat
                }
                if activity.lon > maxLon {
                    maxLon = activity.lon
                }
                if activity.lon < maxLon {
                    minLon = activity.lon
                }
            }
            
            // Move the screen up slightly since the pin sticks out at the top
            var centerLat = (maxLat+minLat) / 2
            centerLat += abs(maxLat-minLat) / 8
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: (maxLon+minLon)/2)
            
            let bboxCorner1  = CLLocation(latitude: maxLat, longitude: maxLon)
            let bboxCorner2 = CLLocation(latitude: minLat, longitude: minLon)
            let distanceInMeters = bboxCorner1.distance(from: bboxCorner2) // result is in meter
            
            let bboxLength = distanceInMeters * 1.5 > 1000 ? distanceInMeters * 1.5 : 1000
            let viewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, bboxLength, bboxLength);
            mapView.setRegion(viewRegion, animated: true)
        }
    }
}
