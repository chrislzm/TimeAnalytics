//
//  TASettingsViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/15/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TASettingsViewController:UIViewController {
    
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var endDate: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func downloadAllUserDataButtonPressed(_ sender: Any) {
        let progressView = TAProgressView.instanceFromNib()
        setupAndHideOverlayView(progressView)
        
        TAModel.sharedInstance().downloadAndProcessAllMovesData(progressView) { (error) in
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
    
    @IBAction func downloadButtonPressed(_ sender: Any) {
        let progressView = TAProgressView.instanceFromNib()
        setupAndHideOverlayView(progressView)

        TAModel.sharedInstance().downloadAndProcessMovesDataInRange(startDate.date, endDate.date,progressView) { (error) in            
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        TAModel.sharedInstance().deleteAllDataFor(["MovesMoveSegment","MovesPlaceSegment","TAPlaceSegment"])
    }
    
    // Creates sets up overlay attributes, hides it, and adds it to the navigation controller view hierarchy
    func setupAndHideOverlayView(_ view:UIView) {
        view.isHidden = true
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        let navControllerView = self.navigationController!.view!
        
        navControllerView.addSubview(view)
        
        let horizontalConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: navControllerView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        self.navigationController?.view.addConstraints([horizontalConstraint,widthConstraint,heightConstraint,bottomConstraint])
    }
}
