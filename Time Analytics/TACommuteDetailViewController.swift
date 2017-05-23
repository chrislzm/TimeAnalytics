//
//  TACommuteDetailViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import MapKit
import UIKit

class TACommuteDetailViewController: TADetailViewController {
    
    // MARK: Properties
    var startName:String?
    var startLat:Double!
    var startLon:Double!
    var endName:String?
    var endLat:Double!
    var endLon:Double!
    
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
    
    
}
