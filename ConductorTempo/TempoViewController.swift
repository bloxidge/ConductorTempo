//
//  TempoViewController.swift
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
class TempoViewController: UIViewController {
    
    // Interface variables
    @IBOutlet weak var tempoLineChart : LineChartView!
    
    // Public variables
    var model : TempoCalculator!
    
    /**
     Called when this view is loaded.
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.updateTempoChart(tempoLineChart)
    }

}
