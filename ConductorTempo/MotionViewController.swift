//
//  MotionViewController.swift
//  ConductorTempo
//
//  Created by Y0075205 on 15/03/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import UIKit
import Charts

/**
 View Controller class for local tempo line chart.
 */
class MotionViewController: UIViewController {
    
    // Interface variables
    @IBOutlet weak var motionLineChart : LineChartView!
    @IBOutlet var motionSegmentControl : UISegmentedControl!
    
    // Public variables
    var model : TempoCalculator!
    
    /**
     Called when the motion sensor selected segment is changed.
     */
    @IBAction func motionSegmentChanged(_ sender: UISegmentedControl) {
        
        model.updateMotionChart(motionLineChart, selectedSegment: sender.selectedSegmentIndex)
    }
    
    /**
     Called when this view is loaded.
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.updateMotionChart(motionLineChart, selectedSegment: motionSegmentControl.selectedSegmentIndex)
    }

}
