//
//  TATableViewCell.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/17/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TAPlaceTableViewCell : UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var timeInOutLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    // Properties
    var lat:Double! = nil
    var lon:Double! = nil
    var name:String! = nil
}
