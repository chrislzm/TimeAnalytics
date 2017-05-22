//
//  ViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        TANetClient.sharedInstance().obtainMovesAuthCode()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didGetMovesAuthCode(_:)), name: Notification.Name("didGetMovesAuthCode"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if let _ = delegate.query {
        }
        TANetClient.sharedInstance().verifyLoggedIntoMoves() { (error) in
            guard error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ShowLocationTableViewController", sender: nil)
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
                    self.performSegue(withIdentifier: "ShowLocationTableViewController", sender: nil)
                }
            }
        }
    }
}

