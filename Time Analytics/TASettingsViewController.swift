//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {

    @IBAction func logOutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can download your Moves data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: confirmLogout))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func confirmLogout(alert:UIAlertAction!) {
        // Clear persistent data
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment","TACommuteSegment"])
        
        // Clear session variables
        TAModel.sharedInstance().deleteMovesLoginInfo()
        
        // Logout, unwind and display login screen
        self.performSegue(withIdentifier: "LogOut", sender: self)
    }
}

