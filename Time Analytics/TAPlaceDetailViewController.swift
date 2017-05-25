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

class TAPlaceDetailViewController: TADetailViewController, UITableViewDelegate {
    
    // MARK: Properties
    
    var lat:Double!
    var lon:Double!
    var name:String!
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

    // MARK: Actions + Alerts

    @IBAction func didTapOnMapView(_ sender: Any) {
        showDetailMapViewController()
    }
    
    // Rename place methods
    
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
        self.present(editDialog, animated: true, completion: nil)
    }
    
    func confirmRenamePlace(_ newName:String) {
        let confirmDialog = UIAlertController(title: "Confirm", message: "Rename this place as:\n'\(newName)' ", preferredStyle: UIAlertControllerStyle.alert)
        confirmDialog.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            self.renamePlace(newName)
        }))
        confirmDialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(confirmDialog, animated: true, completion: nil)
    }
    
    func renamePlace(_ newName:String) {
        // Start activity indicator and display message that we are updating
        let updatingDialog = UIAlertController(title: "Updating", message: " \n", preferredStyle: UIAlertControllerStyle.alert)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.startAnimating()
        spinner.center = CGPoint(x: 135.0, y: 65.5)
        spinner.color = UIColor.black
        updatingDialog.view.addSubview(spinner)
        self.present(updatingDialog, animated: true) { () in
            TAModel.sharedInstance().renamePlaceInAllTAData(self.lat, self.lon, newName)
            self.name = newName
            self.title = newName
            self.updateMapViewAnnotationName()
            updatingDialog.dismiss(animated: true, completion: nil)
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
        placeTableView.allowsSelection = false
        commuteTableView.separatorStyle = .none
        activityTableView.separatorStyle = .none

        // Data Source
        placeHistoryTableData = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@)", [lat,lon], "startTime", false) as! [TAPlaceSegment]

        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "(startLat == %@ AND startLon == %@) OR (endLat == %@ AND endLon == %@)", [lat,lon,lat,lon], "startTime", false) as! [TACommuteSegment]
        
        activityHistoryTableData = getEntityObjectsWithQuery("TAActivitySegment", "placeLat == %@ AND placeLon == %@",[lat,lon], "startTime", false) as! [TAActivitySegment]
        
        // If no results, make sure we have an empty array
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
            
            // Create the cell
            let activityCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceDetailActivityTableViewCell", for: indexPath) as! TAPlaceDetailActivityTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateActivityStringDescriptionsShortDate(activity,currentYear)
            activityCell.timeLabel.text = timeInOutString
            activityCell.lengthLabel.text = lengthString
            activityCell.dateLabel.text = dateString
            activityCell.nameLabel.text = activity.name!
            
            //commuteCell.locationLabel.text = dateString
            cell = activityCell
        }
        return cell
    }
    
    // MARK: Table Delegate methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == commuteTableView {
            let commute = commuteHistoryTableData[indexPath.row]
            showCommuteDetailViewController(commute)
        } else if tableView == activityTableView {
            let activity = activityHistoryTableData[indexPath.row]
            showActivityDetailViewController(activity)
        }
    }
    
    // MARK: Data Methods
    
    func getVisitDataForThisPlace() -> ([Double],[Double],Int,Double) {
        let places = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@)", [lat,lon], "startTime", true) as! [TAPlaceSegment]
        let totalVisits = places.count
        var totalVisitTime:Double = 0
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
    
    func getNumLastMonthVisits() -> Int {
        let oneMonthAgo = Date() - 2678400 // There are this many seconds in a month
        let lastMonthVisits = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@) AND (startTime >= %@)", [lat,lon,oneMonthAgo], nil, nil)
        return lastMonthVisits.count
    }
    
    // MARK: View Helper Methods
    
    func createTableEmptyMessageIn(_ table:UITableView, _ message:String) {
        let tableEmptyMessage = UILabel(frame: table.frame)
        tableEmptyMessage.text = message
        tableEmptyMessage.font = UIFont.systemFont(ofSize: 13)
        tableEmptyMessage.textAlignment = .center
        tableEmptyMessage.backgroundColor = UIColor.white
        table.backgroundView = tableEmptyMessage
    }

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
