//
//  MainViewController.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import UIKit

protocol ProcessDelegate  {
    var text : String { get set }
    var inProgress : Bool { get set }
    var buttonEnabled : Bool { get set }
    var tempo : Float? { get set }
    var accuracy : Float? { get set }
    
    func removeRefreshButton()
}

class MainViewController: UIViewController, ProcessDelegate {
    
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressIndicator: UIActivityIndicatorView!
    @IBOutlet var tempoValueLabel: UILabel!
    @IBOutlet var accuracyValueLabel: UILabel!
    @IBOutlet var metroTempoLabel: UILabel!
    @IBOutlet var metroStepper: UIStepper!
    @IBOutlet var graphsButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIButton!
    
    private var model = TempoCalculator()
    private var metro: Metronome!
    
    var buttonEnabled: Bool {
        get {
            return graphsButton.isEnabled
        }
        set {
            DispatchQueue.main.async {
                self.graphsButton.isEnabled = newValue
            }
        }
    }
    var text: String {
        get {
            return progressLabel.text!
        }
        set {
            DispatchQueue.main.async {
                self.progressLabel.text = newValue
            }
        }
    }
    var inProgress: Bool {
        get {
            return progressIndicator.isAnimating
        }
        set {
            DispatchQueue.main.async {
                if newValue {
                    self.progressIndicator.startAnimating()
                } else {
                    self.progressIndicator.stopAnimating()
                }
            }
        }
    }
    var tempo: Float? {
        get {
            if let tmp = Float(tempoValueLabel.text!) {
                return tmp
            } else {
                return nil
            }
        }
        set {
            DispatchQueue.main.async {
                self.tempoValueLabel.text = String(format: "%0.0f", newValue!)
            }
        }
    }
    var accuracy: Float? {
        get {
            if let tmp = Float(tempoValueLabel.text!) {
                return tmp
            } else {
                return nil
            }
        }
        set {
            DispatchQueue.main.async {
                self.accuracyValueLabel.text = String(format: "%0.1f", newValue!)
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
        model.targetTempo = Float(sender.value)
    }
    
    @IBAction func returnToMainViewController(_ segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.delegate = self
        model.tracker.delegate = self
        
        model.targetTempo = Float(metroStepper.value)
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

