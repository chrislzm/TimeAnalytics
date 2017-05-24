//
//  TAProcessHealthKitDataController.swift
//  Time Analytics
//
//  Created by Chris Leung on 5/22/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit

class TAProcessHealthKitDataController: UIViewController {
    
    var dataChunksToImport = 0
    var dataChunksImported = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup notifications so we know when we finished importing data
        NotificationCenter.default.addObserver(self, selector: #selector(TAProcessHealthKitDataController.didCompleteDataChunk(_:)), name: Notification.Name("didProcessDataChunk"), object: nil)
        
        TAModel.sharedInstance().importHealthKitData() { (dataChunks) in
            DispatchQueue.main.async {
                self.dataChunksToImport = dataChunks
            }
        }
    }
    
    func didCompleteDataChunk(_ notification:Notification) {
        dataChunksImported += 1
        if dataChunksImported == dataChunksToImport {
            // Save to persistent data since the import was done on a background context
            let stack = getCoreDataStack()
            stack.save()
            performSegue(withIdentifier: "FinishedProcessingHealthKitData", sender: nil)
        }
    }
}
