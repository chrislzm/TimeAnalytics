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
    func fadeIn(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0, _ completionHandler: ((_ finished:Bool) -> Void)?) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 1.0 }, completion: completionHandler)
    }
    
    func fadeOut(duration: TimeInterval = 0.25, delay: TimeInterval = 0.0, _ completionHandler: ((_ finished:Bool) -> Void)?) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0.0 }, completion: completionHandler)
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

extension UITabBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 40 // adjust your size here
        return sizeThatFits
    }
}
