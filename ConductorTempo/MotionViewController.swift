//
//  MotionViewController.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 15/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import UIKit
import Charts

class MotionViewController: UIViewController {
    
    var model: TempoCalculator!
    
    @IBOutlet weak var motionLineChart: LineChartView!
    
    @IBAction func updateChart(_ sender: UISegmentedControl) {
        
        model.update(chart: motionLineChart, from: sender)
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }

}
