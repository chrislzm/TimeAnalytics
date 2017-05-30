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
    @IBOutlet weak var refreshActivityView: UIActivityIndicatorView!
    @IBOutlet weak var refreshDataButton: BorderedButton!
    
    // MARK: Actions
    
    @IBAction func refreshDataButtonPressed() {
        startActivityView()
        
        // After this begins, AppDelegate will handle the rest of the data processing flow, including importing HealthKit data
        TAModel.sharedInstance.downloadAndProcessNewMovesData()
    }

    @IBAction func logOutButtonPressed() {
        // Confirmation dialog for logout
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can analyze your data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: logoutConfirmed))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func logoutConfirmed(alert:UIAlertAction!) {
        DispatchQueue.main.async {
            
            // Clear context and persistent data
            self.clearAllData()
            
            // Clear session variables
            TAModel.sharedInstance.deleteAllSessionData()
            
            // Unwind and display login screen
            self.performSegue(withIdentifier: "LogOut", sender: self)
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super .viewDidLoad()

        setLastUpdatedText()
        
        setAutoUpdateLabelText()
        
        // Hide button title when disabled so we can show the activity indicator on top of it
        refreshDataButton.setTitle("", for: .disabled)
        
        // Stop the activity view if we have an error
        errorCompletionHandler = { () in
            DispatchQueue.main.async {
                self.stopActivityView()
            }
        }
    }
    
    override func didCompleteAllUpdates(_ notification: Notification) {
        super.didCompleteAllUpdates(notification)
        self.stopActivityView()
        self.setLastUpdatedText()
    }
    
    // MARK: View Update Methods
    
    func startActivityView() {
        refreshActivityView.startAnimating()
        refreshDataButton.isEnabled = false
    }
    
    func stopActivityView() {
        DispatchQueue.main.async {
            self.refreshActivityView.stopAnimating()
            self.refreshDataButton.isEnabled = true
        }
    }
    
    // Tells the user the last time we updated our data
    func setLastUpdatedText() {
        DispatchQueue.main.async {
            let lastChecked = TANetClient.sharedInstance.lastCheckedForNewData!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.doesRelativeDateFormatting = true
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            let lastUpdatedString = "\(dateFormatter.string(from: lastChecked)) at \(timeFormatter.string(from: lastChecked))"
            
            self.lastUpdatedLabel.text = lastUpdatedString
        }
    }
    
    // Tells the user how often we automatically update
    func setAutoUpdateLabelText() {
        autoUpdateLabel.text = "Automatically Updates Every \(TAModel.AutoUpdateInterval) Minutes"
    }
}

