//
//  TempoViewController.swift
//  ConductorTempo
//
//  Created by Y0075205 on 15/03/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
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
