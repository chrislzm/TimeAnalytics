//
//  TAPlaceDetailViewController.swift
//  Time Analytics
//
//  Shows details about a TAPlaceSegment:
//   - Summary statistics
//   - Line chart with data points and trend line if there are at least 2 or 3 data points respectively (LineChartView)
//   - Map location (MapView)
//   - Visit history with place highlighted whose detail view this belongs to (TableView)
//   - Commute history to/from this place (TableView)
//   - Activity history at this place (TableView)
//
//  Created by Chris Leung on 5/17/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreData
import Foundation
import MapKit
import UIKit

class TAPlaceDetailViewController: TADetailViewController, UITableViewDelegate {
    
    // MARK: Properties
    
    var lat:Double!
    var lon:Double!
    var name:String?
    var startTime:NSDate!
    var endTime:NSDate!
    
    var selectedIndexPath:IndexPath! // Stores the index of the item whose detail view this belongs to
    
    var placeHistoryTableData:[TAPlaceSegment]!
    var commuteHistoryTableData:[TACommuteSegment]!
    var activityHistoryTableData:[TAActivitySegment]!    
    
    // MARK: Outlets
    
    @IBOutlet weak var placeTableView: UITableView!
    @IBOutlet weak var commuteTableView: UITableView!
    @IBOutlet weak var activityTableView: UITableView!
    @IBOutlet weak var visitHistoryLabel: UILabel!
    @IBOutlet weak var commuteHistoryLabel: UILabel!
    @IBOutlet weak var activityHistoryLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var averageTimeLabel: UILabel!
    @IBOutlet weak var pastMonthLabel: UILabel!
    @IBOutlet weak var totalVisitsLabel: UILabel!
    @IBOutlet weak var chartView: LineChartView!

    // MARK: Actions

    @IBAction func didTapOnMapView(_ sender: Any) {
        showDetailMapViewController()
    }
    
    @IBAction func didTapOnLineChartView(_ sender: Any) {
        showDetailLineChartViewController("Length of Visit to \(name!)")
    }
    
    // MARK: Place Renaming Methods
    
    func editButtonPressed() {
        let editDialog = UIAlertController(title: "Edit Place Name", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        editDialog.addTextField() { (textField) in
            textField.text = self.name
        }
        editDialog.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            let textField = editDialog.textFields![0] as UITextField
            self.confirmRenamePlace(textField.text!)
        }))
        editDialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        DispatchQueue.main.async {
            self.present(editDialog, animated: true, completion: nil)
        }
    }
    
    func confirmRenamePlace(_ newName:String) {
        let confirmDialog = UIAlertController(title: "Confirm", message: "Rename this place as:\n'\(newName)' ", preferredStyle: UIAlertControllerStyle.alert)
        confirmDialog.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            self.renamePlace(newName)
        }))
        confirmDialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        DispatchQueue.main.async {
            self.present(confirmDialog, animated: true, completion: nil)
        }
    }
    
    func renamePlace(_ newName:String) {
        // Start activity indicator and display message that we are updating
        let updatingDialog = UIAlertController(title: "Updating", message: " \n", preferredStyle: UIAlertControllerStyle.alert)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.center = CGPoint(x: 135.0, y: 65.5)
        spinner.color = UIColor.black
        updatingDialog.view.addSubview(spinner)
        DispatchQueue.main.async {
            spinner.startAnimating()
            self.present(updatingDialog, animated: true) { () in
                DispatchQueue.main.async {
                    TAModel.sharedInstance.renamePlaceInAllTAData(self.lat, self.lon, newName)
                    self.name = newName
                    self.title = newName
                    self.updateMapViewAnnotationName()
                    updatingDialog.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the view
        title = name
        addEditButton()
        
        // Get data for this place, to be used below
        let(visitDates,visitLengths,totalVisits,totalVisitTime) = getVisitDataForThisPlace()
        
        // SETUP CHART AND MAP VIEWS
        
        setupLineChartView(chartView, visitDates, visitLengths)
        lineChartXVals = visitDates
        lineChartYVals = visitLengths
        setupMapView(mapView)
        
        // SETUP SUMMARY LABELS
        
        totalVisitsLabel.text = "\(totalVisits)"
        
        let lastMonthVisits = getNumLastMonthVisits()
        pastMonthLabel.text = "\(lastMonthVisits)"
        
        let averageVisitTimeString = (StopWatch(totalSeconds: Int(totalVisitTime)/totalVisits)).simpleTimeString
        averageTimeLabel.text = averageVisitTimeString

        let totalVisitTimeString = (StopWatch(totalSeconds: Int(totalVisitTime))).simpleTimeString
        totalTimeLabel.text = totalVisitTimeString

        // SETUP TABLEVIEWS

        // Styles
        placeTableView.separatorStyle = .none
        commuteTableView.separatorStyle = .none
        activityTableView.separatorStyle = .none

        // Data Sources
        placeHistoryTableData = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@)", [lat,lon], "startTime", false) as! [TAPlaceSegment]

        setSelectedIndexPathForPlace() // Find and set the table indexpath for the row whose detail view this belongs to
        
        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "(startLat == %@ AND startLon == %@) OR (endLat == %@ AND endLon == %@)", [lat,lon,lat,lon], "startTime", false) as! [TACommuteSegment]
        
        activityHistoryTableData = getEntityObjectsWithQuery("TAActivitySegment", "placeLat == %@ AND placeLon == %@",[lat,lon], "startTime", false) as! [TAActivitySegment]
        
        // If no results, let the user know
        if commuteHistoryTableData.isEmpty {
            createTableEmptyMessageIn(commuteTableView,"No commutes recorded")
        }
        if activityHistoryTableData.isEmpty {
            createTableEmptyMessageIn(activityTableView,"No activities recorded")
        }
        
        // SETUP TABLE HEADER LABELS
        
        visitHistoryLabel.text = "  Visit History - \(totalVisits) Total"
        
        let totalCommutes = commuteHistoryTableData!.count
        commuteHistoryLabel.text = "  Commute History - \(totalCommutes) Total"
        
        let totalActivities = activityHistoryTableData!.count
        activityHistoryLabel.text = "  Activity History - \(totalActivities) Total"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Select and scroll to the item whose detail view this belongs to
        placeTableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .middle)
        
        // Deselect row if we selected one that caused a segue
        if let selectedRowIndexPath = commuteTableView.indexPathForSelectedRow {
            commuteTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
        else if let selectedRowIndexPath = activityTableView.indexPathForSelectedRow {
            activityTableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
    }
    
    // MARK: UITableView Data Source Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int = 0
        
        if tableView == placeTableView {
            count = placeHistoryTableData.count
        } else if tableView == commuteTableView {
            count = commuteHistoryTableData!.count
        } else if tableView == activityTableView {
            count = activityHistoryTableData!.count
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if tableView == placeTableView {
            let place = placeHistoryTableData[indexPath.row]
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceTableViewCell", for: indexPath) as! TAPlaceDetailTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generatePlaceStringDescriptions(place,currentYear)
            placeCell.timeInOutLabel.text = timeInOutString
            placeCell.lengthLabel.text = lengthString
            placeCell.dateLabel.text = dateString

            // Select (highlight) the cell that contains the place that this detail view belongs to
            if place.startTime == startTime, place.endTime == endTime {
                selectedIndexPath = indexPath
                let backgroundView = UIView()
                backgroundView.backgroundColor = UIColor.yellow
                placeCell.selectedBackgroundView = backgroundView
            }
            
            cell = placeCell
        } else if tableView == commuteTableView {
            let commute = commuteHistoryTableData![indexPath.row]
            let commuteCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceDetailCommuteTableViewCell", for: indexPath) as! TAPlaceDetailCommuteTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,_) = generateCommuteStringDescriptions(commute,nil)
            commuteCell.timeLabel.text = timeInOutString
            commuteCell.lengthLabel.text = lengthString
            if commute.startLat == lat && commute.startLon == lon {
                commuteCell.locationLabel.text = "To \(commute.endName!)"
            } else {
                commuteCell.locationLabel.text = "From \(commute.startName!)"
            }
            cell = commuteCell
        } else if tableView == activityTableView {
            let activity = activityHistoryTableData![indexPath.row]
            let activityCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceDetailActivityTableViewCell", for: indexPath) as! TAPlaceDetailActivityTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateActivityStringDescriptionsShortDate(activity,currentYear)
            activityCell.timeLabel.text = timeInOutString
            activityCell.lengthLabel.text = lengthString
            activityCell.dateLabel.text = dateString
            activityCell.nameLabel.text = activity.name!
            
            cell = activityCell
        }
        return cell
    }
    
    // MARK: Table Delegate methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == placeTableView, indexPath != selectedIndexPath {
            // Don't allow the user to highlight another row whose detail view this doesn't belong to
            tableView.deselectRow(at: indexPath, animated: false)
        } else if tableView == commuteTableView {
            let commute = commuteHistoryTableData[indexPath.row]
            showCommuteDetailViewController(commute)
        } else if tableView == activityTableView {
            let activity = activityHistoryTableData[indexPath.row]
            showActivityDetailViewController(activity)
        }
    }
    
    // Don't allow the user to unhighlight the row whose detail view this belongs to
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard tableView == placeTableView else {
            return indexPath
        }
        return nil
    }
    
    // MARK: Data Methods
    
    // Find the row in the table whose detail view this belongs to
    func setSelectedIndexPathForPlace() {
        
        var dataIndex = 0
        
        for i in 0..<placeHistoryTableData.count {
            if placeHistoryTableData[i].lat == lat, placeHistoryTableData[i].lon == lon, placeHistoryTableData[i].startTime == startTime {
                dataIndex = i
                break
            }
        }
        
        selectedIndexPath = IndexPath(row: dataIndex, section: 0)
    }
    
    // Convenience method for assembling data needed to setup the view
    func getVisitDataForThisPlace() -> ([Double],[Double],Int,Double) {
        let places = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@)", [lat,lon], "startTime", true) as! [TAPlaceSegment]
        let totalVisits = places.count
        var totalVisitTime:Double = 0
        
        // These two arrays are used in the Line Chart
        var visitLengths = [Double]()
        var visitDates = [Double]()
        for place in places {
            let startTime = place.startTime! as Date
            let endTime = place.endTime! as Date
            let visitTime = endTime.timeIntervalSince(startTime)
            totalVisitTime += visitTime
            visitLengths.append(visitTime)
            visitDates.append(startTime.timeIntervalSinceReferenceDate)
        }
        return (visitDates,visitLengths,totalVisits,totalVisitTime)
    }
    
    // Get total number of visits to this place in the last month
    func getNumLastMonthVisits() -> Int {
        let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let lastMonthVisits = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@) AND (startTime >= %@)", [lat,lon,oneMonthAgo], nil, nil)
        return lastMonthVisits.count
    }
    
    // MARK: View Helper Methods

    func addEditButton() {
        let settingsButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target:self, action: #selector(TAPlaceDetailViewController.editButtonPressed))
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    func updateMapViewAnnotationName() {
        mapView.removeAnnotations(mapView.annotations)
        mapViewAnnotations.removeAll()
        setupMapView(mapView)
    }
    
    override func setupMapView(_ mapView:MKMapView) {
        super.setupMapView(mapView)
        
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        annotation.title = name
        mapView.addAnnotation(annotation)
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, DefaultMapViewRegionSize, DefaultMapViewRegionSize);
        mapView.setRegion(viewRegion, animated: true)
        
        // Save data for segue
        mapViewAnnotations.append(annotation)
        mapViewCenter = coordinate
        mapViewRegionSize = DefaultMapViewRegionSize
    }
}
