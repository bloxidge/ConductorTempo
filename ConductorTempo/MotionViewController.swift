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
    
    @IBOutlet weak var lineChart: LineChartView!
    
    private var model = TempoCalculator()
    
    @IBAction func updateChart(_ sender: UISegmentedControl) {
        
        model.update(chart: lineChart, from: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
