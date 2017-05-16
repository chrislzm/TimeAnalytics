//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
        
        // Try getting moves data
        NetClient.sharedInstance().getMovesDataFrom(yesterday!, Date()) { (result,error) in
            guard error == nil else {
                print(error)
                return
            }
            
            NetClient.sharedInstance().parseAndSaveMovesData(result!)
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        Model.sharedInstance().deleteAllMovesData()
    }
}
