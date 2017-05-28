//
//  TALoginViewController.swift
//  Time Analytics
//
//  Handles user login. Will enter the app directly if we are already logged in.
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class ViewController: TAViewController {

    @IBOutlet weak var launchScreenImageView: UIImageView!
    @IBOutlet weak var launchScreenActivityView: UIActivityIndicatorView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        TANetClient.sharedInstance().obtainMovesAuthCode()
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The app delegate will notify us here if it has received a moves auth code
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didGetMovesAuthCode(_:)), name: Notification.Name("didGetMovesAuthCode"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Check if we are already logged in
        if TAModel.sharedInstance().isLoggedIn() {
            performSegue(withIdentifier: "AlreadyLoggedIn", sender: nil)
        } else {
            // Ensure we've cleared all invalid moves session data
            TAModel.sharedInstance().deleteAllSessionData()
            
            // Clear all data that might have been partially processed in a previously failed login
            clearAllData()
            
            // Hide the overlays to reveal the login screen
            launchScreenActivityView.fadeOut() { (finished) in
                self.launchScreenActivityView.isHidden = true
            }
            launchScreenImageView.fadeOut() { (finished) in
                self.launchScreenImageView.isHidden = true
            }
        }
    }

    func didGetMovesAuthCode(_ notification:Notification) {
        let authCode = notification.userInfo![AnyHashable("code")] as! String

        // Initiate step 2/2 of the login auth flow
        TANetClient.sharedInstance().loginWithMovesAuthCode(authCode: authCode) { (error) in
            guard error == nil else {
                self.displayErrorAlert(error!, nil)
                return
            }

            // Segue to data import screen if we are logged in
            TANetClient.sharedInstance().verifyLoggedIntoMoves() { (error) in
                guard error == nil else {
                    self.displayErrorAlert(error!, nil)
                    return
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "FirstLogin", sender: nil)
                }
            }
        }
    }
}

