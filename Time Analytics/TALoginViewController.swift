//
//  ViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var launchScreenImageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        TANetClient.sharedInstance().obtainMovesAuthCode()
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didGetMovesAuthCode(_:)), name: Notification.Name("didGetMovesAuthCode"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TANetClient.sharedInstance().verifyLoggedIntoMoves() { (error) in
            // Show the login screen if there was an error (e.g. we are not logged in)
            DispatchQueue.main.async {
                guard error == nil else {
                    self.launchScreenImageView.fadeOut() { (finished) in
                        self.launchScreenImageView.removeFromSuperview()
                    }
                    return
                }
                self.performSegue(withIdentifier: "AlreadyLoggedIn", sender: nil)
            }
        }
    }

    func didGetMovesAuthCode(_ notification:Notification) {
        let authCode = notification.userInfo![AnyHashable("code")] as! String
        
        TANetClient.sharedInstance().loginWithMovesAuthCode(authCode: authCode) { (error) in
            guard error == nil else {
                self.displayErrorAlert(error!)
                return
            }

            TANetClient.sharedInstance().verifyLoggedIntoMoves() { (error) in
                guard error == nil else {
                    self.displayErrorAlert(error!)
                    return
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "FirstLogin", sender: nil)
                }
            }
        }
    }
}

