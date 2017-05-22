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

class TAPlaceDetailViewController: UIViewController, UITableViewDataSource {
    
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
    
    var lat:Double! = nil
    var lon:Double! = nil
    var name:String! = nil
    var placeHistoryTableData = [TAPlaceSegment]()
    var commuteHistoryTableData = [TACommuteSegment]()
    var activityHistoryTableData = [String]()
    
    // MARK: Actions
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
        navigationController?.setToolbarHidden(true, animated: true)
        title = name
        placeTableView.separatorStyle = .none
        commuteTableView.separatorStyle = .none
        activityTableView.separatorStyle = .none
        
        // Setup and add the Edit button
        let settingsButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target:self, action: #selector(TAPlaceDetailViewController.editButtonPressed))
        navigationItem.rightBarButtonItem = settingsButton
        
        // Create a fetchrequest
        let stack = getCoreDataStack()
        var fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        
        // Update label with total visits over last month
        let oneMonthAgo = Date() - 2678400 // There are this many seconds in a month
        var pred = NSPredicate(format: "(lat == %@) AND (lon == %@) AND (startTime >= %@)", argumentArray: [lat,lon,oneMonthAgo])
        fr.predicate = pred
        let lastMonthVisits = try! stack.context.fetch(fr) as! [TAPlaceSegment]
        pastMonthLabel.text = "\(lastMonthVisits.count)"
        
        // Get data for summary labels and chart
        pred = NSPredicate(format: "(lat == %@) AND (lon == %@)", argumentArray: [lat,lon])
        fr.predicate = pred
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        let places = try! stack.context.fetch(fr) as! [TAPlaceSegment]
        
        // Update label with totals
        let totalVisits = places.count
        visitHistoryLabel.text = "  Visit History - \(totalVisits) Total"
        totalVisitsLabel.text = "\(totalVisits)"
        
        // Update labels with average visit time
        var totalVisitSeconds:Double = 0.0
        var visitLengths = [Double]()
        var visitDates = [Double]()
        for place in places {
            let startTime = place.startTime! as Date
            let endTime = place.endTime! as Date
            let visitTime = endTime.timeIntervalSince(startTime)
            totalVisitSeconds += visitTime
            visitLengths.append(visitTime)
            visitDates.append(startTime.timeIntervalSinceReferenceDate)
        }
        let averageVisitTime = StopWatch(totalSeconds: Int(totalVisitSeconds)/totalVisits)
        let totalVisitTime = StopWatch(totalSeconds: Int(totalVisitSeconds))
        totalTimeLabel.text = "\(totalVisitTime.simpleTimeString)"
        averageTimeLabel.text = "\(averageVisitTime.simpleTimeString)"
        
        // Setup Chart
        chartView.chartDescription!.text = ""
        chartView.maxVisibleCount = 0
        let legend = chartView.legend
        legend.enabled = false
        let leftAxis = chartView.leftAxis
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawTopYLabelEntryEnabled = false
        leftAxis.drawBottomYLabelEntryEnabled = false
        let rightAxis = chartView.rightAxis
        rightAxis.drawGridLinesEnabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawTopYLabelEntryEnabled = false
        rightAxis.drawBottomYLabelEntryEnabled = false
        let xAxis = chartView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.drawLabelsEnabled = false
        
        var dataEntries = [ChartDataEntry]()
        for i in 0..<visitLengths.count {
            let dataEntry = ChartDataEntry(x: visitDates[i], y: visitLengths[i])
            dataEntries.append(dataEntry)
        }
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Visit Time")
        lineChartDataSet.circleRadius = 1
        lineChartDataSet.circleColors = [UIColor.purple]
        lineChartDataSet.drawCircleHoleEnabled = false
        
        var lineCharDataSets = [lineChartDataSet]
        // Add trendline if we have enough data
        if visitDates.count > 2 {
            let (slope,yintercept) = calculateTrendLine(visitDates,visitLengths)
            // Get y values for first and last dates on the chart
            let trendy1 = (slope*visitDates.first!)+yintercept
            let trendy2 = (slope*visitDates.last!)+yintercept
            let trendStartPoint = ChartDataEntry(x: visitDates.first!, y: trendy1)
            let trendEndPoint = ChartDataEntry(x: visitDates.last!, y: trendy2)
            let trendLineDataSet = LineChartDataSet(values: [trendStartPoint,trendEndPoint], label: "Trend Line")
            trendLineDataSet.drawCirclesEnabled = false
            trendLineDataSet.drawCircleHoleEnabled = false
            trendLineDataSet.colors = [UIColor.red]
            lineCharDataSets.append(trendLineDataSet)
        }
        let lineChartData = LineChartData(dataSets: lineCharDataSets)
        chartView.data = lineChartData
        
        // Setup Mapview = Add the geocoded location as an annotation to the map
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
        
        // Generate data for the Place History view
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        pred = NSPredicate(format: "(lat == %@) AND (lon == %@)", argumentArray: [lat,lon])
        fr.predicate = pred
        placeHistoryTableData = try! stack.context.fetch(fr) as! [TAPlaceSegment]
        
        // Generate data for the Commute History view
        fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TACommuteSegment")
        pred = NSPredicate(format: "(startLat == %@ AND startLon == %@) OR (endLat == %@ AND endLon == %@)", argumentArray: [lat,lon,lat,lon])
        fr.predicate = pred
        commuteHistoryTableData = try! stack.context.fetch(fr) as! [TACommuteSegment]
        
        // Update label with totals
        let totalCommutes = commuteHistoryTableData.count
        commuteHistoryLabel.text = "  Commute History - \(totalCommutes) Total"

        if activityHistoryTableData.isEmpty {
            let tableEmptyMessage = UILabel(frame: activityTableView.frame)
            tableEmptyMessage.text = "No activities recorded"
            tableEmptyMessage.textAlignment = .center
            tableEmptyMessage.backgroundColor = UIColor.white
            activityTableView.backgroundView = tableEmptyMessage
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == self.placeTableView {
            count = placeHistoryTableData.count
        } else if tableView == self.commuteTableView {
            count = commuteHistoryTableData.count
        }
        
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
            let commuteCell = tableView.dequeueReusableCell(withIdentifier: "TACommuteDetailTableViewCell", for: indexPath) as! TACommuteDetailTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,startName,endName,dateString) = generateCommuteStringDescriptions(commute)
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    // MARK: Helper Functions
    
    func calculateTrendLine(_ xValues:[Double],_ yValues:[Double]) -> (Double,Double) {
        let n = xValues.count
        var a:Double = 0.0
        var sumx:Double = 0.0
        var sumxsquared:Double = 0.0
        var sumy:Double = 0.0
        for i in 0..<n {
            a += xValues[i] * yValues[i]
            sumx += xValues[i]
            sumy += yValues[i]
            sumxsquared += xValues[i] * xValues[i]
        }
        a *= Double(n)
        let b = sumx * sumy
        let c = sumxsquared * Double(n)
        let d = sumx * sumx
        let slope_m = (a-b)/(c-d)
        
        let e = sumy
        let f = slope_m*sumx
        let y_intercept = (e-f)/Double(n)
        
        return (slope_m,y_intercept)
    }
}
