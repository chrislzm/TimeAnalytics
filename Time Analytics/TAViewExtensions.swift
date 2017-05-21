//
//  TAViewExtensions.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/20/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

extension UIView {
    
    // Fade In/Out animation for UIView objects
    func fadeIn(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 }, completion: nil)
    }
    
    func fadeOut(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0.0 }, completion: nil)
    }
    
}

extension UIViewController {
    
    // Displays a generic alert with a single OK button, takes a title and message as arguments
    func displayErrorAlert(_ error:String?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: error, message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
