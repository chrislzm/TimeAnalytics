//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Settings panel for the app. Displays the last time we checked for udpates. Allows user to manually refresh data or logout.
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:TADataUpdateViewController {
    
    // MARK: Outlets
    
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var autoUpdateLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    // MARK: Actions
    
    @IBAction func refreshDataButtonPressed(_ sender: Any) {
        // After this begins, AppDelegate will handle the rest of the data processing flow, including importing HealthKit data
        TAModel.sharedInstance().downloadAndProcessNewMovesData()
    }

    @IBAction func logOutButtonPressed(_ sender: Any) {
        // Confirmation dialog for logout
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can analyze your data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: logoutConfirmed))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func logoutConfirmed(alert:UIAlertAction!) {
        DispatchQueue.main.async {
            
            self.activityView.isHidden = false
            
            // Clear persistent data
            let stack = self.getCoreDataStack()
            let context = stack.context
            TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment","TACommuteSegment","TAActivitySegment"],context)
            
            // Clear session variables
            TAModel.sharedInstance().deleteMovesSessionInfo()
            
            // Save all changes
            stack.save()
            
            self.activityView.isHidden = true
            
            // Unwind and display login screen
            self.performSegue(withIdentifier: "LogOut", sender: self)
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super .viewDidLoad()

        setLastUpdatedText()
        
        setAutoUpdateLabelText()
    }
    
    override func didCompleteUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView(completionHandler: nil)
            self.setLastUpdatedText()
        }
    }
    
    // MARK: View Update Methods
    
    // Tells the user the last time we updated our data
    func setLastUpdatedText() {
        let lastChecked = TANetClient.sharedInstance().lastCheckedForNewData!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.doesRelativeDateFormatting = true
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let lastUpdatedString = "\(dateFormatter.string(from: lastChecked)) at \(timeFormatter.string(from: lastChecked))"
        
        lastUpdatedLabel.text = lastUpdatedString
    }
    
    // Tells the user how often we automatically update
    func setAutoUpdateLabelText() {
        autoUpdateLabel.text = "Automatically Updates Every \(TANetClient.MovesApi.Constants.AutoUpdateMinutes) Minutes"
    }
}

