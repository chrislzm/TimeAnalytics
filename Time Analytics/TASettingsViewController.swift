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
    @IBAction func rescueTimeButtonPressed() {
        editRescueTimeApiKey()
    }

    @IBAction func logOutButtonPressed() {
        // Confirmation dialog for logout
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can analyze your data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: logoutConfirmed))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Action Helper Methods
    
    // RescueTime API Key
    
    func editRescueTimeApiKey() {
        let dialog = UIAlertController(title: "RescueTime API Key", message: "Entering a RescueTime API Key here will allow us to display your computer usage along with your other activities. Please note this feature is currently under development.", preferredStyle: UIAlertControllerStyle.alert)
        dialog.addTextField() { (textField) in
            textField.text = TAModel.sharedInstance.getRescueTimeApiKey()
        }
        dialog.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            let textField = dialog.textFields![0] as UITextField
            self.confirmRescueTimeApiKey(textField.text!)
        }))
        dialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        DispatchQueue.main.async {
            self.present(dialog, animated: true, completion: nil)
        }
    }
    
    func confirmRescueTimeApiKey(_ apiKey:String) {
        let confirmDialog = UIAlertController(title: "Confirm", message: "RescueTime API Key:\n\(apiKey)", preferredStyle: UIAlertControllerStyle.alert)
        confirmDialog.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            self.saveRescueTimeApiKey(apiKey)
        }))
        confirmDialog.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        DispatchQueue.main.async {
            self.present(confirmDialog, animated: true, completion: nil)
        }
    }
    
    func saveRescueTimeApiKey(_ apiKey:String) {
        TAModel.sharedInstance.setRescueTimeApiKey(apiKey)

        let updatedDialog = UIAlertController(title: "Updated", message: "We will use this API key to request updates from RescueTime", preferredStyle: UIAlertControllerStyle.alert)
        updatedDialog.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(updatedDialog, animated: true, completion: nil)
        }
    }
    
    // Logout
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
            
            let lastUpdatedString = "Last Updated - \(timeFormatter.string(from: lastChecked)) \(dateFormatter.string(from: lastChecked))"
            
            self.lastUpdatedLabel.text = lastUpdatedString
        }
    }
    
    // Tells the user how often we automatically update
    func setAutoUpdateLabelText() {
        autoUpdateLabel.text = "Automatically Updates Every \(TAModel.AutoUpdateInterval) Minutes"
    }
}

