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
    @IBOutlet var motionSegmentControl: UISegmentedControl!
    
    @IBAction func updateChart(_ sender: UISegmentedControl) {
        
        model.updateMotionChart(motionLineChart, selectedSegment: sender.selectedSegmentIndex)
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.updateMotionChart(motionLineChart, selectedSegment: motionSegmentControl.selectedSegmentIndex)
    }

}
