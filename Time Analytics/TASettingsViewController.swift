//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {

    @IBOutlet weak var lastUpdatedLabel: UILabel!
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can download your Moves data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: confirmLogout))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()

        navigationController?.setToolbarHidden(true, animated: true)
        
        let lastChecked = TANetClient.sharedInstance().movesLastChecked!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.doesRelativeDateFormatting = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let lastUpdatedString = "\(dateFormatter.string(from: lastChecked)) at \(timeFormatter.string(from: lastChecked))"

        lastUpdatedLabel.text = lastUpdatedString
    }
    
    func confirmLogout(alert:UIAlertAction!) {
        // Clear persistent data
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment","TACommuteSegment","TAActivitySegment"])
        
        // Clear session variables
        TAModel.sharedInstance().deleteMovesLoginInfo()
        
        // Logout, unwind and display login screen
        self.performSegue(withIdentifier: "LogOut", sender: self)
    }
}

