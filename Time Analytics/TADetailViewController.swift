//
//  TADetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import Charts
import UIKit

class TADetailViewController: UIViewController {
    
    func getEntityObjectsWithQuery(_ entityName:String, _ query:String,_ argumentArray:[Any], _ sortKey:String?, _ isAscending:Bool?) -> [AnyObject] {
        let stack = getCoreDataStack()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let pred = NSPredicate(format: query, argumentArray: argumentArray)
        fr.predicate = pred
        if let sort = sortKey, let ascending = isAscending {
            fr.sortDescriptors = [NSSortDescriptor(key: sort, ascending: ascending)]
        }
        return try! stack.context.fetch(fr)
    }

    func setupLineChartView(_ chartView:LineChartView, _ xValues:[Double],_ yValues:[Double]) {
        
        // Setup appearance: Remove all labels, gridlines, annotations, etc...
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
        
        // Create line from data
        var dataEntries = [ChartDataEntry]()
        for i in 0..<yValues.count {
            let dataEntry = ChartDataEntry(x: xValues[i], y: yValues[i])
            dataEntries.append(dataEntry)
        }
        let lineChartDataSet = LineChartDataSet(values: dataEntries, label: "Visit Time")
        
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
        chartView.data = lineChartData
    }
    
    
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
