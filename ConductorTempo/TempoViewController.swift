//
//  TempoViewController.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 15/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import UIKit
import Charts

class TempoViewController: UIViewController {
    
    var model: TempoCalculator!
    
    @IBOutlet weak var tempoLineChart: LineChartView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.updateTempoChart(tempoLineChart)
    }

}
