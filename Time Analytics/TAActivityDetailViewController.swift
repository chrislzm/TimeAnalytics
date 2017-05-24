//
//  TAActivityDetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/23/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import CoreLocation
import MapKit
import UIKit

class TAActivityDetailViewController: TADetailViewController {
    var name:String?
    var activityHistoryTableData = [TAActivitySegment]()
    
    @IBOutlet weak var activityHistoryTableView: UITableView!
    
    override func viewDidLoad() {
        
        // Setup the view
        setTitle()
        
        // Get data for this place, to be used below
        /*let(commuteDates,commuteLengths,totalCommutes,totalCommuteTime) = getDataForThisCommute()
        
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
        */
        // SETUP TABLEVIEWS
        
        // Styles
        activityHistoryTableView.separatorStyle = .none
        activityHistoryTableView.allowsSelection = false
        
        // Data Source
        activityHistoryTableData = getEntityObjectsWithQuery("TAActivitySegment", "name == %@", [name!], "startTime", false) as! [TAActivitySegment]
        
        //timeBeforeDepartingTableData = getDeparturePlaceHistory(commuteHistoryTableData)
        //timeAfterArrivingTableData = getDestinationPlaceHistory(commuteHistoryTableData)
        
        // SETUP TABLE HEADER LABELS
        
        //setCommuteHistoryTableHeaderLabelText(totalCommutes)
        //setTimeBeforeDepartingTableHeaderLabel()
        //setTimeAfterArrivingTableHeaderLabel()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count:Int?
        
        if tableView == activityHistoryTableView {
            count = activityHistoryTableData.count
        }
        
        return count!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = UITableViewCell()
        
        if tableView == activityHistoryTableView {
            // Find the right notebook for this indexpath
            let activity = activityHistoryTableData[indexPath.row]
            
            // Create the cell
            let activityCell = tableView.dequeueReusableCell(withIdentifier: "TAActivityDetailActivityTableViewCell", for: indexPath) as! TAActivityDetailActivityTableViewCell
            
            // Get descriptions and assign to cell label
            let (timeInOutString,lengthString,dateString) = generateActivityStringDescriptions(activity)
            activityCell.timeLabel.text = timeInOutString
            activityCell.lengthLabel.text = lengthString
            activityCell.dateLabel.text = dateString
            cell = activityCell
        }
        
        return cell
    }
    
    func setTitle() {
        title = "\(name!)"
    }
}
