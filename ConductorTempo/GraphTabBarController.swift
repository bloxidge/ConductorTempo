//
//  GraphTabBarController.swift
//  ConductorTempo
//
//  Created by Y0075205 on 15/03/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import UIKit

class GraphTabBarController: UITabBarController {
    
    var model: TempoCalculator!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let tabVCs = self.viewControllers {
            (tabVCs[0] as! TempoViewController).model = self.model
            (tabVCs[1] as! MotionViewController).model = self.model
        }
    }

}
