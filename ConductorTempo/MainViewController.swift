//
//  MainViewController.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, ProgressDelegate {
    
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressIndicator: UIActivityIndicatorView!
    @IBOutlet var tempoValueLabel: UILabel!
    @IBOutlet var metroTempoLabel: UILabel!
    @IBOutlet var metroStepper: UIStepper!
    @IBOutlet var graphsButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIButton!
    
    private var model = TempoCalculator()
    private var metro: Metronome!
    
    var buttonEnabled: Bool {
        set {
            DispatchQueue.main.async {
                self.graphsButton.isEnabled = newValue
            }
        }
        get {
            return graphsButton.isEnabled
        }
    }
    var text: String {
        set {
            DispatchQueue.main.async {
                self.progressLabel.text = newValue
            }
        }
        get {
            return progressLabel.text!
        }
    }
    var inProgress: Bool {
        set {
            DispatchQueue.main.async {
                if newValue {
                    self.progressIndicator.startAnimating()
                } else {
                    self.progressIndicator.stopAnimating()
                }
            }
        }
        get {
            return progressIndicator.isAnimating
        }
    }
    var tempo: Int? {
        set {
            DispatchQueue.main.async {
                self.tempoValueLabel.text = "\(newValue!)"
            }
        }
        get {
            if let tmp = Int(tempoValueLabel.text!) {
                return tmp
            } else {
                return nil
            }
        }
    }
    
    func removeRefreshButton() {
        
        refreshButton.isHidden = true
    }
    
    @IBAction func refreshPressed() {
        
        model.checkWatchIsPaired()
    }
    
    @IBAction func metroSwitchPressed(_ sender: UISwitch) {
        
        metro.isPlaying = sender.isOn
    }
    
    @IBAction func metroTempoReleased(_ sender: UIStepper) {
        
        metro.tempo = sender.value
    }
    
    @IBAction func metroTempoChanged(_ sender: UIStepper) {
        
        metroTempoLabel.text = String(format: "%0.0f", sender.value)
    }
    
    @IBAction func returnToMainViewController(_ segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.delegate = self
        model.tracker.delegate = self
        
        model.checkWatchIsPaired()
        
        metro = Metronome(tempo: metroStepper.value)
        metro.isPlaying = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? GraphTabBarController {
            destinationVC.model = model
        }
    }

}

