//
//  TADetailMapViewController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/24/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import MapKit
import UIKit

class TADetailMapViewController:UIViewController {
    
    // MARK: Properties
    var annotations:[MKAnnotation]!
    var regionSize:CLLocationDistance!
    var center:CLLocationCoordinate2D!
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.addAnnotations(annotations)
        mapView.selectAnnotation(annotations.first!, animated: true)

        let viewRegion = MKCoordinateRegionMakeWithDistance(center, regionSize, regionSize);
        mapView.setRegion(viewRegion, animated: true)
    }
}
