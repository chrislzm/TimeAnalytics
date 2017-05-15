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
        let moveHook = "moves://app/authorize?" + "client_id=Z0hQuORANlkEb_BmDVu8TntptuUoTv6o&redirect_uri=time-analytics://app&scope=activity location".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let moveUrl = URL(string: moveHook)
        print(moveUrl!.absoluteString)
        if UIApplication.shared.canOpenURL(moveUrl!)
        {
            UIApplication.shared.open(moveUrl!, options: [:]) { (result) in
                print("Success")
            }
        } else {
            print("That didn't work")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didGetMovesAuthCode(_:)), name: Notification.Name("didGetMovesAuthCode"), object: nil)
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
        
        NetClient.sharedInstance().loginWithMovesAuthCode(authCode: authCode) { (error) in
            guard error == nil else {
                print("Error login in: \(error!)")
                return
            }
            print("Moves login successful!!! Access Token:")
            
            print(NetClient.sharedInstance().movesAccessToken)

            // Try getting moves data
            NetClient.sharedInstance().getMovesDataFrom(Date(), Date()) { (result,error) in
                guard error == nil else {
                    print(error)
                    return
                }
                
                print ("Got data from moves!")
                print(result)
            }
        }
    }
}

