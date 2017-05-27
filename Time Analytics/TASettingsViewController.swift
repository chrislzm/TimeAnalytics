//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:TADataUpdateViewController {
    
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var autoUpdateLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBAction func refreshDataButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().downloadAndProcessNewMovesData()
    }

    @IBAction func logOutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Log Out", message: "All Time Analytics data will cleared. You can download your Moves data again by logging back in.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.default, handler: confirmLogout))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        setLastUpdatedText()
        
        setAutoUpdateLabelText()
    }
    
    override func didCompleteUpdate(_ notification:Notification) {
        DispatchQueue.main.async {
            self.removeProgressView(completionHandler: nil)
            self.setLastUpdatedText()
        }
    }
    
    func confirmLogout(alert:UIAlertAction!) {
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
            
            // Logout, unwind and display login screen
            self.performSegue(withIdentifier: "LogOut", sender: self)
        }
    }
    
    // MARK: View Update Methods
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
    
    func setAutoUpdateLabelText() {
        autoUpdateLabel.text = "Automatically Updates Every \(TANetClient.MovesApi.Constants.AutoUpdateMinutes) Minutes"
    }
}

