//
//  TADetailLineChartViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Charts
import UIKit

class TADetailLineChartViewController:TADetailViewController {
    
    // MARK: Properties
    var xValues:[Double]!
    var yValues:[Double]!

    // MARK: Outlets
    @IBOutlet weak var lineChartView: LineChartView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
