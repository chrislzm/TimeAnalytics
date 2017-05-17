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
        TANetClient.sharedInstance().downloadAllMovesUserData() { (data,error) in
            guard error == nil else {
                print(error)
                return
            }            
        }
    }
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        let start = startDate.date
        let end = endDate.date
        
        // Try getting moves data
        TANetClient.sharedInstance().getMovesDataFrom(start, end) { (result,error) in
            guard error == nil else {
                print(error)
                return
            }
            
            TAModel.sharedInstance().parseAndSaveMovesData(result!)
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment"])
    }
}
