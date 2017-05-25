//
//  TADetailLineChartViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import UIKit

class TADetailLineChartViewController:TADetailViewController, IAxisValueFormatter {
    
    // MARK: Properties
    var xValues:[Double]!
    var yValues:[Double]!
    var dataName:String?

    // MARK: Outlets
    @IBOutlet weak var lineChartView: LineChartView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Line Chart View
        let scaleSize:[Double] = [60.0,60.0,60.0,24.0,7.0,30.0,365.0]
        let scaleName = ["Seconds","Minutes","Hours","Days","Weeks","Months","Years"]
        var scaleUp = true
        var scale = 0
        
        // Convert data to largest size possible for scale
        while (scaleUp == true) {
            scale += 1
            scaleUp = false
            for i in 0..<yValues.count {
                yValues[i] = yValues[i]/scaleSize[scale]
                if yValues[i] > scaleSize[scale+1] {
                    scaleUp = true
                }
            }
        }
        
        // Setup appearance: Remove all labels, gridlines, annotations, etc...
        lineChartView.chartDescription!.text = "\(dataName!) (In \(scaleName[scale])) Over Time"

        let legend = lineChartView.legend
        legend.enabled = true
        let leftAxis = lineChartView.leftAxis
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawLabelsEnabled = true
        leftAxis.drawTopYLabelEntryEnabled = true
        leftAxis.drawBottomYLabelEntryEnabled = true
        let rightAxis = lineChartView.rightAxis
        rightAxis.drawGridLinesEnabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawTopYLabelEntryEnabled = false
        rightAxis.drawBottomYLabelEntryEnabled = false
        let xAxis = lineChartView.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.drawLabelsEnabled = true
        xAxis.valueFormatter = self
        
        // Create line from data
        var dataEntries = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let dataEntry = ChartDataEntry(x: xValues[i], y: yValues[i])
            dataEntries.append(dataEntry)
        }
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Time (\(scaleName[scale]))")
        
        // Set line appearance
        lineChartDataSet.circleRadius = 1
        lineChartDataSet.circleColors = [UIColor.purple]
        lineChartDataSet.drawCircleHoleEnabled = false
        
        // Add to data sets to display
        var lineCharDataSets = [lineChartDataSet]
        
        // Create a new trendline if we have enough data for it
        if xValues.count > 2 {
            
            let (slope,yintercept) = calculateTrendLine(xValues,yValues)
            // Get y values for first and last dates on the chart
            let trendy1 = (slope*xValues.first!)+yintercept
            let trendy2 = (slope*xValues.last!)+yintercept
            
            // Create beginning and endpoints of trend line
            let trendStartPoint = ChartDataEntry(x: xValues.first!, y: trendy1)
            let trendEndPoint = ChartDataEntry(x: xValues.last!, y: trendy2)
            let trendLineDataSet = LineChartDataSet(values: [trendStartPoint,trendEndPoint], label: "Trend Line")
            
            // Set line appearance
            trendLineDataSet.drawCirclesEnabled = false
            trendLineDataSet.drawCircleHoleEnabled = false
            trendLineDataSet.colors = [UIColor.red]
            
            // Add to data sets to display
            lineCharDataSets.append(trendLineDataSet)
        }
        
        // Add lines to chart
        let lineChartData = LineChartData(dataSets: lineCharDataSets)
        lineChartView.data = lineChartData


    }
    
    // IAxisValueFormatter Delegate Method
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d ''YY"
        let date = Date(timeIntervalSinceReferenceDate: value)
        var dateString = formatter.string(from: date)
        if let year = currentYear {
            dateString = removeYearIfSame(dateString,year,-4)
        }
        return dateString
    }
}
