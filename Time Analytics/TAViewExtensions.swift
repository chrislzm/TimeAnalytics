//
//  TAViewExtensions.swift
//  Time Analytics
//
//  Miscellaneous extensions for UIView objects
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

extension UITabBar {
    
    // Adjust the default size of the tabbar to be shorter
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 40
        return sizeThatFits
    }
}
