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

struct TAViewConstants {
    static let viewFadeInDuration:Double = 0.25
    static let viewFadeInDelay:Double = 0.0
    static let viewFadeInAlpha:CGFloat = 1.0
    static let viewFadeOutDuration:Double = 0.25
    static let viewFadeOutDelay:Double = 0.0
    static let viewFadeOutAlpha:CGFloat = 0.0
    
    static let tabBarHeight:CGFloat = 40
}

extension UIView {
    
    // Fade In/Out animation for UIView objects
    func fadeIn(duration: TimeInterval = TAViewConstants.viewFadeInDuration, delay: TimeInterval = TAViewConstants.viewFadeInDelay, _ completionHandler: ((_ finished:Bool) -> Void)?) {
        UIView.animate(withDuration: duration, animations: { self.alpha = TAViewConstants.viewFadeInAlpha }, completion: completionHandler)
    }
    
    func fadeOut(duration: TimeInterval = TAViewConstants.viewFadeInDuration, delay: TimeInterval = TAViewConstants.viewFadeOutDelay, _ completionHandler: ((_ finished:Bool) -> Void)?) {
        UIView.animate(withDuration: duration, animations: { self.alpha = TAViewConstants.viewFadeOutAlpha }, completion: completionHandler)
    }
}

extension UITabBar {
    
    // Adjust the default size of the tabbar to be shorter
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = TAViewConstants.tabBarHeight
        return sizeThatFits
    }
}
