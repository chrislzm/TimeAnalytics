//
//  TACommuteDetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreLocation
import MapKit
import UIKit

class TACommuteDetailViewController: TADetailViewController, MKMapViewDelegate {
    
    // MARK: Properties
    var startName:String?
    var startLat:Double!
    var startLon:Double!
    var endName:String?
    var endLat:Double!
    var endLon:Double!
    
    var commuteHistoryTableData = [TACommuteSegment]()
    var timeBeforeDepartingTableData = [TAPlaceSegment]()
    var timeAfterDepartingTableData = [TAPlaceSegment]()
    
    // MARK: Outlets
    
    @IBOutlet weak var totalCommutesLabel: UILabel!
    @IBOutlet weak var pastMonthTotalCommutesLabel: UILabel!
    @IBOutlet weak var averageTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var commuteHistoryTableHeaderLabel: UILabel!
    @IBOutlet weak var commuteHistoryTableView: UITableView!
    
    @IBOutlet weak var timeBeforeDepartingTableHeaderLabel: UILabel!
    @IBOutlet weak var timeBeforeDepartingTableView: UITableView!
    
    @IBOutlet weak var timeAfterArrivingTableHeaderLabel: UILabel!
    @IBOutlet weak var timeAfterArrivingTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the view
        title = "\(startName!) to \(endName!)"
        
        // Get data for this place, to be used below
        let(commuteDates,commuteLengths,totalCommutes,totalCommuteTime) = getDataForThisCommute()
        
        setupLineChartView(lineChartView, commuteDates, commuteLengths)
        setupMapView()
        
        // SETUP SUMMARY LABELS
        
        totalCommutesLabel.text = "\(totalCommutes)"
        
        let lastMonthCommutes = getNumLastMonthCommutes()
        pastMonthTotalCommutesLabel.text = "\(lastMonthCommutes)"
        
        let averageCommuteTimeString = (StopWatch(totalSeconds: Int(totalCommuteTime)/totalCommutes)).simpleTimeString
        averageTimeLabel.text = averageCommuteTimeString
        
        let totalCommuteTimeString = (StopWatch(totalSeconds: Int(totalCommuteTime))).simpleTimeString
        totalTimeLabel.text = totalCommuteTimeString
        
        // SETUP TABLEVIEWS
        
        // Styles
        commuteHistoryTableView.separatorStyle = .none
        timeBeforeDepartingTableView.separatorStyle = .none
        timeAfterArrivingTableView.separatorStyle = .none
        
        // Data Source
        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@", [startLat,startLon,endLat,endLon], "startTime", false) as! [TACommuteSegment]
        
        timeBeforeDepartingTableData = getDeparturePlaceHistory(commuteHistoryTableData)
        timeAfterDepartingTableData = getDestinationPlaceHistory(commuteHistoryTableData)
        
        // SETUP TABLE HEADER LABELS
        
        commuteHistoryTableHeaderLabel.text = "  Commute History - \(totalCommutes) Total"
        timeBeforeDepartingTableHeaderLabel.text = "  Before Departure - \(startName!)"
        timeAfterArrivingTableHeaderLabel.text = "  After Arrival - \(endName!)"
    }
    
    
    // MARK: Data Methods
    
    //let(commuteDates,commuteLengths,totalCommutes,totalCommuteTime) = getDataForThisCommute()
    func getDataForThisCommute() -> ([Double],[Double],Int,Double) {
        let commutes = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@", [startLat,startLon,endLat,endLon], "startTime", true) as! [TACommuteSegment]
        let totalCommutes = commutes.count
        var totalCommuteTime:Double = 0
        var commuteLengths = [Double]()
        var commuteDates = [Double]()
        for commute in commutes {
            let startTime = commute.startTime! as Date
            let endTime = commute.endTime! as Date
            let commuteTime = endTime.timeIntervalSince(startTime)
            totalCommuteTime += commuteTime
            commuteLengths.append(commuteTime)
            commuteDates.append(startTime.timeIntervalSinceReferenceDate)
        }
        return (commuteDates,commuteLengths,totalCommutes,totalCommuteTime)
    }
    
    func getNumLastMonthCommutes() -> Int {
        let oneMonthAgo = Date() - 2678400 // There are this many seconds in a month
        let lastMonthCommutes = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@ AND startTime >= %@", [startLat,startLon,endLat,endLon,oneMonthAgo], nil, nil)
        return lastMonthCommutes.count
    }
    
    // Gets a list of place data for the departure place on these commutes
    func getDeparturePlaceHistory(_ commutes:[TACommuteSegment]) -> [TAPlaceSegment] {
        var departurePlaceHistory = [TAPlaceSegment]()
        for commute in commutes {
            let place = getEntityObjectsWithQuery("TAPlaceSegment", "lat == %@ AND lon == %@ AND endTime == %@", [commute.startLat,commute.startLon,commute.startTime!], nil, nil) as! [TAPlaceSegment]
            departurePlaceHistory.append(place[0])
        }
        return departurePlaceHistory
    }
    
    // Gets a list of place data for the destination on these commutes
    func getDestinationPlaceHistory(_ commutes:[TACommuteSegment]) -> [TAPlaceSegment] {
        var destinationPlaceHistory = [TAPlaceSegment]()
        for commute in commutes {
            let place = getEntityObjectsWithQuery("TAPlaceSegment", "lat == %@ AND lon == %@ AND startTime == %@", [commute.endLat,commute.endLon,commute.endTime!], nil, nil) as! [TAPlaceSegment]
            destinationPlaceHistory.append(place[0])
        }
        return destinationPlaceHistory
    }
    
    // MARK: View Methods
    
    func setupMapView() {
        let startAnnotation = MKPointAnnotation()
        let startCoordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLon)
        startAnnotation.coordinate = startCoordinate
        mapView.addAnnotation(startAnnotation)
        
        let endAnnotation = MKPointAnnotation()
        let endCoordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
        endAnnotation.coordinate = endCoordinate
        mapView.addAnnotation(endAnnotation)
        
        // Move the screen up slightly since the pin sticks out at the top
        var centerLat = (startLat+endLat) / 2
        centerLat += abs(startLat-endLat) / 8
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: (startLon+endLon)/2)

        let startLocation  = CLLocation(latitude: startLat, longitude: startLon)
        let endLocation = CLLocation(latitude: endLat, longitude: endLon)
        let distanceInMeters = startLocation.distance(from: endLocation) // result is in meter

        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, distanceInMeters * 1.5, distanceInMeters * 1.5);
        mapView.setRegion(viewRegion, animated: true)
    }
}
