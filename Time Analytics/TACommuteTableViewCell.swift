//
//  TACommuteTableViewCell.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TACommuteTableViewCell : UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var startNameLabel: UILabel!
    @IBOutlet weak var endNameLabel: UILabel!

    // Properties
    var startLat:Double! = nil
    var startLon:Double! = nil
    var startName:String! = nil
    var endLat:Double! = nil
    var endLon:Double! = nil
    var endName:String! = nil
}
