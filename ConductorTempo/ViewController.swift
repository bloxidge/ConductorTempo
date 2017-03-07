//
//  ViewController.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {
    
    @IBOutlet weak var lineChart: LineChartView!
    
    private var detector = TempoDetector()
    
    @IBAction func updateChart(_ sender: UIButton) {
        
        var dataEntries = [ChartDataEntry]()
        var time = detector.motionVectors!.time
        var values = detector.motionVectors!.acceleration.x
        
        for (index, value) in values.enumerated() {
            let entry = ChartDataEntry(x: Double(time[index]), y: Double(value))
            dataEntries.append(entry)
        }
        
        let dataSet = LineChartDataSet(values: dataEntries, label: "After")
        dataSet.lineWidth = 2.0
        dataSet.colors = [UIColor.blue]
        dataSet.drawCirclesEnabled = false
        
        let lineData = LineChartData(dataSet: dataSet)
        lineChart.data = lineData
        lineChart.chartDescription?.text = "Attitude"
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

}

