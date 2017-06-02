//
//  TACommuteDetailViewController.swift
//  Time Analytics
//
//  Shows details about a TACommuteSegment:
//   - Summary statistics
//   - Line chart with data points and trend line if there are at least 2 or 3 data points respectively (LineChartView)
//   - Map location (MapView)
//   - Commute history with commute highlighted whose detail view this belongs to (TableView)
//   - Time spent at place departure point before the departure on this commute (TableView)
//   - Time spent at place arrival point after the arrival on this commute (TableView)
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreLocation
import MapKit
import UIKit

class TACommuteDetailViewController: TADetailViewController, UITableViewDelegate {
    
    // MARK: Properties
    
    var startName:String?
    var startLat:Double!
    var startLon:Double!
    var startTime:NSDate!
    var endName:String?
    var endLat:Double!
    var endLon:Double!
    var endTime:NSDate!
    
    var commuteHistoryTableData = [TACommuteSegment]()
    var timeBeforeDepartingTableData = [TAPlaceSegment]()
    var timeAfterArrivingTableData = [TAPlaceSegment]()
    
    var didTapOnDepartureTable:Bool = false
    var didTapOnArrivalTable:Bool = false
    
    var selectedIndexPath:IndexPath! // Stores the index of the item whose detail view this belongs to
    
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
    
    @IBAction func didTapOnMapView(_ sender: Any) {
        showDetailMapViewController()
    }
    
    @IBAction func didTapOnLineChartView(_ sender: Any) {
        showDetailLineChartViewController("Length of Commute from \(startName!) to \(endName!)")
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
        lineChartXVals = commuteDates
        lineChartYVals = commuteLengths

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
        timeBeforeDepartingTableView.separatorStyle = .none
        timeAfterArrivingTableView.separatorStyle = .none
        
        // Data Sources
        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@", [startLat,startLon,endLat,endLon], "startTime", false) as! [TACommuteSegment]
        
        setSelectedIndexPathForCommute() // Find and set the table indexpath for the row whose detail view this belongs to
        
        timeBeforeDepartingTableData = getDeparturePlaceHistory(commuteHistoryTableData)
        timeAfterArrivingTableData = getDestinationPlaceHistory(commuteHistoryTableData)
        
        // SETUP TABLE HEADER LABELS
        
        setCommuteHistoryTableHeaderLabelText(totalCommutes)
        setTimeBeforeDepartingTableHeaderLabel()
        setTimeAfterArrivingTableHeaderLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Select and scroll to the item whose detail view this belongs to
        commuteHistoryTableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .middle)
        
        // Check if place names were updated, and update if necessary
        if didTapOnDepartureTable {
            updatePlaceNames(true)
            didTapOnDepartureTable = false
        } else if didTapOnArrivalTable {
            updatePlaceNames(false)
            didTapOnArrivalTable = false
        }
        
        // Deselect row if we selected one that caused a segue
        if let selectedRowIndexPath = timeBeforeDepartingTableView.indexPathForSelectedRow {
            timeBeforeDepartingTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
        else if let selectedRowIndexPath = timeAfterArrivingTableView.indexPathForSelectedRow {
            timeAfterArrivingTableView.deselectRow(at: selectedRowIndexPath, animated: true)
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
            let commute = commuteHistoryTableData[indexPath.row]
            let commuteCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailCommuteTableViewCell", for: indexPath) as! TACommuteDetailCommuteTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateCommuteStringDescriptions(commute,currentYear)
            commuteCell.timeLabel.text = timeInOutString
            commuteCell.lengthLabel.text = lengthString
            commuteCell.dateLabel.text = dateString

            // Select (highlight) the cell that contains the commute that this detail view belongs to
            if commute.startTime == startTime, commute.endTime == endTime {
                selectedIndexPath = indexPath
                highlightTableCell(commuteCell)
            }

            cell = commuteCell
            
        } else if tableView == timeBeforeDepartingTableView {
            let place = timeBeforeDepartingTableData[indexPath.row]
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailDepartureTableViewCell", for: indexPath) as! TACommuteDetailDepartureTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generatePlaceStringDescriptions(place,currentYear)
            placeCell.timeLabel.text = timeInOutString
            placeCell.lengthLabel.text = lengthString
            placeCell.dateLabel.text = dateString
            cell = placeCell
            
        } else if tableView == timeAfterArrivingTableView {
            let place = timeAfterArrivingTableData[indexPath.row]
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

    // MARK: Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == commuteHistoryTableView, indexPath != selectedIndexPath {
            // Don't allow the user to highlight another row whose detail view this doesn't belong to
            tableView.deselectRow(at: indexPath, animated: false)
        } else if tableView == timeBeforeDepartingTableView {
            // Save tap so we know to update the place name, in case it was edited
            didTapOnDepartureTable = true
            let place = timeBeforeDepartingTableData[indexPath.row]
            showPlaceDetailViewController(place)
        } else if tableView == timeAfterArrivingTableView {
            didTapOnArrivalTable = true
            let place = timeAfterArrivingTableData[indexPath.row]
            showPlaceDetailViewController(place)
        }
    }
    
    // Don't allow the user to unhighlight the row whose detail view this belongs to
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView == commuteHistoryTableView {
            return nil
        } else {
            return indexPath
        }
    }
    
    // MARK: Data Methods
    
    // Find the row in the table whose detail view this belongs to
    func setSelectedIndexPathForCommute() {
        
        var dataIndex = 0
        
        for i in 0..<commuteHistoryTableData.count {
            if commuteHistoryTableData[i].startTime == startTime, commuteHistoryTableData[i].endTime == endTime {
                dataIndex = i
                break
            }
        }
        
        selectedIndexPath = IndexPath(row: dataIndex, section: 0)
    }
    
    // Convenience method for assembling data needed to setup the view
    func getDataForThisCommute() -> ([Double],[Double],Int,Double) {
        let commutes = getEntityObjectsWithQuery("TACommuteSegment", "startLat == %@ AND startLon == %@ AND endLat == %@ AND endLon == %@", [startLat,startLon,endLat,endLon], "startTime", true) as! [TACommuteSegment]
        let totalCommutes = commutes.count
        var totalCommuteTime:Double = 0
        
        // These two arrays are used in the Line Chart
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
    
    // Get total number of times we made this commute over the last month
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
    
    // If the user tapped on a place and renamed it, we need to reflect that change in this view
    func updatePlaceNames(_ isDeparturePlace:Bool) {
        if isDeparturePlace {
            let startPlace = getTAPlaceSegment(startLat, startLon, startTime as Date, false)
            if startName != startPlace.name  {
                startName = startPlace.name
                setTitle()
                setTimeBeforeDepartingTableHeaderLabel()
            }
        } else {
            let endPlace = getTAPlaceSegment(endLat, endLon, endTime as Date, true)
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

    // Displays both start and end points of the commute and centers+sizes the map accordingly to show them both
    override func setupMapView(_ mapView:MKMapView) {
        super.setupMapView(mapView)
        
        let startAnnotation = MKPointAnnotation()
        let startCoordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLon)
        startAnnotation.coordinate = startCoordinate
        startAnnotation.title = startName
        mapView.addAnnotation(startAnnotation)
        
        let endAnnotation = MKPointAnnotation()
        let endCoordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
        endAnnotation.coordinate = endCoordinate
        endAnnotation.title = endName
        mapView.addAnnotation(endAnnotation)
        
        // Move the screen up slightly since the pin sticks out at the top
        var centerLat = (startLat+endLat) / 2 // Midpoint of two latitudes
        centerLat += abs(startLat-endLat) / 8 // Move view up by 20% (1/8)
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: (startLon+endLon)/2)

        let startLocation  = CLLocation(latitude: startLat, longitude: startLon)
        let endLocation = CLLocation(latitude: endLat, longitude: endLon)
        let distanceInMeters = startLocation.distance(from: endLocation) // result is in meter

        let regionSize = CLLocationDistance(distanceInMeters * 1.5) // Expand the view region to 1.5 times the distance between the two points
        let viewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, regionSize, regionSize);
        mapView.setRegion(viewRegion, animated: true)
        
        // Save data for segue
        mapViewAnnotations.append(startAnnotation)
        mapViewAnnotations.append(endAnnotation)
        mapViewRegionSize = regionSize
        mapViewCenter = centerCoordinate
    }
}
