//
//  TACommuteTableViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/21/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TACommuteTableViewController: TATableViewController {

    func showPlacesButtonPressed() {
        // Grab the DetailVC from Storyboard
        let placesController = self.storyboard!.instantiateViewController(withIdentifier: "TAPlaceTableViewController") as! TAPlaceTableViewController
        
        let navigationController = self.navigationController!
        navigationController.setViewControllers([placesController], animated: false)
        
        //        self.navigationController?.popToRootViewController(animated: false)
        //      self.navigationController?.pushViewController(commutesController, animated: true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NAvigation setup
        let showCommutesButton = UIBarButtonItem(title: "Places", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TACommuteTableViewController.showPlacesButtonPressed))
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.setToolbarItems([showCommutesButton], animated: true)
    }
}
