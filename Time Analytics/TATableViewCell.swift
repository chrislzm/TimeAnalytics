//
//  TATableViewCell.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/17/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation
import UIKit

class TATableViewCell : UITableViewCell {
    
    // MARK: Outlets
    @IBOutlet weak var timeInLabel: UILabel!
    @IBOutlet weak var timeOutLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
}
