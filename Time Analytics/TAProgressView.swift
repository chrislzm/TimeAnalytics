//
//  TAProgressView.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/20/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TAProgressView: UIView {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var totalProgress:Float!
    var currentProgress:Float = 0
    
    func addProgress(_ amountProgressed:Float) {
        currentProgress += amountProgressed
        progressView.setProgress((currentProgress/totalProgress), animated: true)
    }
    
    class func instanceFromNib() -> TAProgressView {
        return UINib(nibName: "TAProgressView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TAProgressView
    }
 }
