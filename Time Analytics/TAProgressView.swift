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
    
    var defaultText = "Downloading Data"
    var totalProgress:Float!
    var currentProgress:Float = 0
    
    func addProgress(_ amountProgressed:Float) {
        DispatchQueue.main.async {
            self.currentProgress += amountProgressed
            var percentComplete = self.currentProgress/self.totalProgress
            percentComplete = percentComplete > 1 ? 1 : percentComplete
            self.progressView.setProgress(percentComplete, animated: true)
            self.titleLabel.text = "\(self.defaultText) (\(Int(percentComplete*100))%)"
        }
    }
    
    func didCompleteDataChunk(_ notification:Notification) {
        
        addProgress(1)
        if currentProgress == totalProgress {
            DispatchQueue.main.async {
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
            NotificationCenter.default.addObserver(self, selector: #selector(TAProgressView.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        }
    }
    
    func removeFromObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func instanceFromNib() -> TAProgressView {
        return UINib(nibName: "TAProgressView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TAProgressView
    }
 }
