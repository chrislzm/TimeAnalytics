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

class TACommuteDetailViewController: TADetailViewController {
    
    // MARK: Properties
    
    var startName:String?
    var startLat:Double!
    var startLon:Double!
    var startTime:Date!
    var endName:String?
    var endLat:Double!
    var endLon:Double!
    var endTime:Date!
    
    var commuteHistoryTableData = [TACommuteSegment]()
    var timeBeforeDepartingTableData = [TAPlaceSegment]()
    var timeAfterArrivingTableData = [TAPlaceSegment]()
    
    var didTapOnDepartureTable:Bool = false
    var didTapOnArrivalTable:Bool = false
    
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

    // MARK: Actions
    
    @IBAction func didTapOnDepartureTable(_ sender: Any) {
        if !timeBeforeDepartingTableData.isEmpty {
            didTapOnDepartureTable = true
            let place = timeBeforeDepartingTableData[0]
            showPlaceDetailViewController(place)
        }
    }
    
    @IBAction func didTapOnArrivalTable(_ sender: Any) {
        if !timeBeforeDepartingTableData.isEmpty {
            didTapOnArrivalTable = true
            let place = timeAfterArrivingTableData[0]
            showPlaceDetailViewController(place)
        }
    }

    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the view
        setTitle()
        
        // Get data for this place, to be used below
        let(commuteDates,commuteLengths,totalCommutes,totalCommuteTime) = getDataForThisCommute()
        
        // SETUP CHART AND MAP VIEWS
        
        setupLineChartView(lineChartView, commuteDates, commuteLengths)
        setupMapView(mapView)
        
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
        commuteHistoryTableView.allowsSelection = false
        timeBeforeDepartingTableView.separatorStyle = .none
        timeBeforeDepartingTableView.allowsSelection = false
        timeAfterArrivingTableView.separatorStyle = .none
        timeAfterArrivingTableView.allowsSelection = false
        
        // Data Source
        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@", [startLat,startLon,endLat,endLon], "startTime", false) as! [TACommuteSegment]
        
        timeBeforeDepartingTableData = getDeparturePlaceHistory(commuteHistoryTableData)
        timeAfterArrivingTableData = getDestinationPlaceHistory(commuteHistoryTableData)
        
        // SETUP TABLE HEADER LABELS
        
        setCommuteHistoryTableHeaderLabelText(totalCommutes)
        setTimeBeforeDepartingTableHeaderLabel()
        setTimeAfterArrivingTableHeaderLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if place names were updated, and update if necessary
        if didTapOnDepartureTable {
            updatePlaceNames(true)
            didTapOnDepartureTable = false
        } else if didTapOnArrivalTable {
            updatePlaceNames(false)
            didTapOnArrivalTable = false
        }
    }
    
    // MARK: UITableView Data Source Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == commuteHistoryTableView {
            count = commuteHistoryTableData.count
        } else if tableView == timeBeforeDepartingTableView {
            count = timeBeforeDepartingTableData.count
        } else if tableView == timeAfterArrivingTableView {
            count = timeAfterArrivingTableData.count
        }
        
        return count!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if tableView == commuteHistoryTableView {
            // Find the right notebook for this indexpath
            let commute = commuteHistoryTableData[indexPath.row]
            
            // Create the cell
            let commuteCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailCommuteTableViewCell", for: indexPath) as! TACommuteDetailCommuteTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateCommuteStringDescriptions(commute,currentYear)
            commuteCell.timeLabel.text = timeInOutString
            commuteCell.lengthLabel.text = lengthString
            commuteCell.dateLabel.text = dateString
            cell = commuteCell
            
        } else if tableView == timeBeforeDepartingTableView {
            
            // Find the right notebook for this indexpath
            let place = timeBeforeDepartingTableData[indexPath.row]
            
            // Create the cell
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailDepartureTableViewCell", for: indexPath) as! TACommuteDetailDepartureTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generatePlaceStringDescriptions(place,currentYear)
            placeCell.timeLabel.text = timeInOutString
            placeCell.lengthLabel.text = lengthString
            placeCell.dateLabel.text = dateString
            cell = placeCell
            
        } else if tableView == timeAfterArrivingTableView {
            
            // Find the right notebook for this indexpath
            let place = timeAfterArrivingTableData[indexPath.row]
            
            // Create the cell
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailDestinationTableViewCell", for: indexPath) as! TACommuteDetailDestinationTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generatePlaceStringDescriptions(place,currentYear)
            placeCell.timeLabel.text = timeInOutString
            placeCell.lengthLabel.text = lengthString
            placeCell.dateLabel.text = dateString
            cell = placeCell
        }
        return cell
    }

    // MARK: Data Methods
    
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
    
    func updatePlaceNames(_ isDeparturePlace:Bool) {
        if isDeparturePlace {
            let startPlace = getTAPlaceSegment(startLat, startLon, startTime, false)
            if startName != startPlace.name  {
                startName = startPlace.name
                setTitle()
                setTimeBeforeDepartingTableHeaderLabel()
            }
        } else {
            let endPlace = getTAPlaceSegment(endLat, endLon, endTime, true)
            if endName != endPlace.name {
                endName = endPlace.name
                setTitle()
                setTimeAfterArrivingTableHeaderLabel()
            }
            
        }
    }
    
    // MARK: View Methods
    
    func setTitle() {
        title = "\(startName!) to \(endName!)"
    }
    
    func setCommuteHistoryTableHeaderLabelText(_ totalCommutes:Int) {
        commuteHistoryTableHeaderLabel.text = "  Commute History - \(totalCommutes) Total"
    }
    
    func setTimeBeforeDepartingTableHeaderLabel() {
        timeBeforeDepartingTableHeaderLabel.text = "  \(startName!) - Before Departure"
    }
    func setTimeAfterArrivingTableHeaderLabel() {
        timeAfterArrivingTableHeaderLabel.text = "  \(endName!) - After Arrival"
    }

    override func setupMapView(_ mapView:MKMapView) {
        super.setupMapView(mapView)
        
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
