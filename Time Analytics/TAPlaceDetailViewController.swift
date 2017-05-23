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

class TAPlaceDetailViewController: TADetailViewController {
    
    // MARK: Properties
    
    var lat:Double! = nil
    var lon:Double! = nil
    var name:String! = nil
    var placeHistoryTableData = [TAPlaceSegment]()
    var commuteHistoryTableData = [TACommuteSegment]()
    var activityHistoryTableData = [String]()
    
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

    // MARK: Action + Alerts for Renaming Place
    
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
        
        setupLineChartView(chartView, visitDates, visitLengths)
        setupMapView()
        
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

        // Data Source
        placeHistoryTableData = getEntityObjectsWithQuery("TAPlaceSegment", "(lat == %@) AND (lon == %@)", [lat,lon], "startTime", false) as! [TAPlaceSegment]

        commuteHistoryTableData = getEntityObjectsWithQuery("TACommuteSegment", "(startLat == %@ AND startLon == %@) OR (endLat == %@ AND endLon == %@)", [lat,lon,lat,lon], "startTime", false) as! [TACommuteSegment]

        // If empty
        if commuteHistoryTableData.isEmpty {
            createTableEmptyMessageIn(commuteTableView,"No commutes recorded")
        }
        if activityHistoryTableData.isEmpty {
            createTableEmptyMessageIn(activityTableView,"No activities recorded")
        }
        
        // SETUP TABLE HEADER LABELS
        
        visitHistoryLabel.text = "  Visit History - \(totalVisits) Total"
        
        let totalCommutes = commuteHistoryTableData.count
        commuteHistoryLabel.text = "  Commute History - \(totalCommutes) Total"
    }
    
    // MARK: UITableView Data Source Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == self.placeTableView {
            count = placeHistoryTableData.count
        } else if tableView == self.commuteTableView {
            count = commuteHistoryTableData.count
        }
        
        return count!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if tableView == self.placeTableView {
            
            // Find the right notebook for this indexpath
            let place = placeHistoryTableData[indexPath.row]
            
            // Create the cell
            let placeCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceTableViewCell", for: indexPath) as! TAPlaceDetailTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,_,dateString) = generatePlaceStringDescriptions(place)
            placeCell.timeInOutLabel.text = timeInOutString
            placeCell.lengthLabel.text = lengthString
            placeCell.dateLabel.text = dateString
            cell = placeCell
            
        } else if tableView == self.commuteTableView {
            // Find the right notebook for this indexpath
            let commute = commuteHistoryTableData[indexPath.row]
            
            // Create the cell
            let commuteCell = tableView.dequeueReusableCell(withIdentifier: "TAPlaceDetailCommuteTableViewCell", for: indexPath) as! TAPlaceDetailCommuteTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,startName,endName,_) = generateCommuteStringDescriptions(commute)
            commuteCell.timeLabel.text = timeInOutString
            commuteCell.lengthLabel.text = lengthString
            if commute.startLat == lat && commute.startLon == lon {
                commuteCell.locationLabel.text = "To \(endName)"
            } else {
                commuteCell.locationLabel.text = "From \(startName)"
            }
            //commuteCell.locationLabel.text = dateString
            cell = commuteCell
        }
        return cell
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
        tableEmptyMessage.textAlignment = .center
        tableEmptyMessage.backgroundColor = UIColor.white
        table.backgroundView = tableEmptyMessage
    }

    func addEditButton() {
        let settingsButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target:self, action: #selector(TAPlaceDetailViewController.editButtonPressed))
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    func setupMapView() {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
    }

}
