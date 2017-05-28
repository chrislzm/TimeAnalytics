//
//  TAProgressView.swift
//  Time Analytics
//
//  A view that contains a progress view and title with % complete.
//    -Increments its progress every time it observes a "didProcessMovesDataChunk" notification or "didProcessHealthKitDataChunk" notification
//    -Dismisses itself once it reaches 100%
//    -It can also be dismissed by calling the removeProgressView method in TAViewController
//
//  Created by Chris Leung on 5/20/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TAProgressView: UIView {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var defaultText = "Downloading Data"
    var totalProgress:Float!
    var currentProgress:Float = 0
    
    func addProgress(_ amountProgressed:Float) {
        self.currentProgress += amountProgressed
        var percentComplete = self.currentProgress/self.totalProgress
        // If somehow we got over 100%, adjust the % and dismiss ourselves
        if percentComplete > 1 {
            percentComplete = 1
            currentProgress = totalProgress
        }
        self.progressView.setProgress(percentComplete, animated: true)
        self.titleLabel.text = "\(self.defaultText) (\(Int(percentComplete*100))%)"
    }
    
    func didCompleteDataChunk(_ notification:Notification) {
        DispatchQueue.main.async {
            self.addProgress(1)
            // If we're at 100%, dismiss ourself
            if self.currentProgress == self.totalProgress {
                self.fadeOut() { (finished) in
                    if finished {
                        self.removeFromObservers()
                        self.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func setupDefaultProperties() {
        DispatchQueue.main.async {
            self.progressView.setProgress(0, animated: false)
            self.titleLabel.text = "\(self.defaultText) (0%)"
            NotificationCenter.default.addObserver(self, selector: #selector(TAProgressView.didCompleteDataChunk(_:)), name: Notification.Name("didProcessHealthKitDataChunk"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(TAProgressView.didCompleteDataChunk(_:)), name: Notification.Name("didProcessMovesDataChunk"), object: nil)
        }
    }
    
    func removeFromObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func instanceFromNib() -> TAProgressView {
        return UINib(nibName: "TAProgressView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TAProgressView
    }
 }
