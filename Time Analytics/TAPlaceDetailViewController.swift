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
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var averageTimeLabel: UILabel!
    @IBOutlet weak var pastMonthLabel: UILabel!
    @IBOutlet weak var totalVisitsLabel: UILabel!
    @IBOutlet weak var chartView: LineChartView!
    
    var lat:Double! = nil
    var lon:Double! = nil
    var name:String! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup tableview
        tableView = placeTableView
        tableView.separatorStyle = .none

        // Set the title
        title = name
        
        // Get the context
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.stack.context
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "TAPlaceSegment")
        
        // Update label with total visits over last month
        let oneMonthAgo = Date() - 2678400 // There are this many seconds in a month
        var pred = NSPredicate(format: "(lat == %@) AND (lon == %@) AND (startTime >= %@)", argumentArray: [lat,lon,oneMonthAgo])
        fr.predicate = pred
        let stack = getCoreDataStack()
        let lastMonthVisits = try! stack.context.fetch(fr) as! [TAPlaceSegment]
        pastMonthLabel.text = "\(lastMonthVisits.count)"
        
        
        // Get data for summary labels and chart
        pred = NSPredicate(format: "(lat == %@) AND (lon == %@)", argumentArray: [lat,lon])
        fr.predicate = pred
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        let places = try! stack.context.fetch(fr) as! [TAPlaceSegment]
        
        // Update labels with total visits
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
        
        // Add trendline to chart
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
        
        let lineChartData = LineChartData(dataSets: [lineChartDataSet,trendLineDataSet])
        chartView.data = lineChartData
        
        // Setup Mapview = Add the geocoded location as an annotation to the map
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Set the MapView to a 1km * 1km box around the geocoded location
        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        mapView.setRegion(viewRegion, animated: true)
        
        // Now create the FetchedResultsController for the TableView
        fr.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        pred = NSPredicate(format: "(lat == %@) AND (lon == %@)", argumentArray: [lat,lon])
        fr.predicate = pred
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: "startTime", cacheName: nil)
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
