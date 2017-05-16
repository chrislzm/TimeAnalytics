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
    
    @IBAction func deleteMovesDataPressed(_ sender: Any) {
        TAModel.sharedInstance().deleteAllMovesData()
    }
    @IBAction func downloadMovesDataPressed(_ sender: Any) {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
        
        // Try getting moves data
        TANetClient.sharedInstance().getMovesDataFrom(yesterday!, Date()) { (result,error) in
            guard error == nil else {
                print(error)
                return
            }
            
            print ("Got data from moves!")
            print(result)
            
            Model.sharedInstance().parseAndSaveMovesData(result!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didGetMovesAuthCode(_:)), name: Notification.Name("didGetMovesAuthCode"), object: nil)
        
        TANetClient.sharedInstance().verifyLoggedIntoMoves() { (error) in
            guard error == nil else {
                print("Error: Not logged into Moves")
                return
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ShowLocationTableViewController", sender: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if let query = delegate.query {
            print("Received query in viewcontroller: \(query)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didGetMovesAuthCode(_ notification:Notification) {
        let authCode = notification.userInfo![AnyHashable("code")] as! String
        print("Got auth code! \(authCode)")
        
        TANetClient.sharedInstance().loginWithMovesAuthCode(authCode: authCode) { (error) in
            guard error == nil else {
                print("Error login in: \(error!)")
                return
            }
            print("Moves login successful!")
        }
    }
}

