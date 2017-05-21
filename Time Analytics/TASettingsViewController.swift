//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {
    
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    
    @IBAction func downloadAllUserDataButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().downloadAndProcessAllMovesData() { (error) in
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().downloadAndProcessMovesDataInRange(startDate.date, endDate.date) { (error) in
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment"])
    }
}
