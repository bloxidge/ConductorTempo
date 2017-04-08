//
//  MainViewController.swift
//  ConductorTempo
//
//  Created by Y0075205 on 23/02/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import UIKit

/**
 Class for the main view controller. Implements ProcessDelegate for updating messages and other properties.
 */
class MainViewController: UIViewController, ProcessDelegate {
    
    // Interface variables
    @IBOutlet var progressLabel      : UILabel!
    @IBOutlet var progressIndicator  : UIActivityIndicatorView!
    @IBOutlet var tempoValueLabel    : UILabel!
    @IBOutlet var accuracyValueLabel : UILabel!
    @IBOutlet var metroTempoLabel    : UILabel!
    @IBOutlet var metroStepper       : UIStepper!
    @IBOutlet var graphsButton       : UIBarButtonItem!
    @IBOutlet var refreshButton      : UIButton!
    
    // Private variables
    private var model = TempoCalculator()
    private var metro : Metronome!
    
    // ProcessDelegate variables
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
    
    /**
     ProcessDelegate method. Removes the 'Refresh' button once the Apple Watch is connected successfully.
     */
    func removeRefreshButton() {
        
        if !refreshButton.isHidden {
            refreshButton.isHidden = true
        }
    }
    
    /**
     Called when the 'Refresh' button is pressed.
     */
    @IBAction func refreshPressed() {
        
        model.checkWatchIsPaired()
    }
    
    /**
     Called when the Metronome switch is pressed.
     */
    @IBAction func metroSwitchPressed(_ sender: UISwitch) {
        
        metro.isPlaying = sender.isOn
    }
    
    /**
     Called when the metronome tempo stepper button is released.
     */
    @IBAction func metroTempoReleased(_ sender: UIStepper) {
        
        metro.tempo = sender.value
    }
    
    /**
     Called when the metronome tempo stepper value is changed.
     */
    @IBAction func metroTempoChanged(_ sender: UIStepper) {
        
        metroTempoLabel.text = String(format: "%0.0f", sender.value)
        model.targetTempo = Float(sender.value)
    }
    
    /**
     Required for exiting modal segue and returning to this view controller.
     */
    @IBAction func returnToMainViewController(_ segue: UIStoryboardSegue) {
    }
    
    /**
     Called when this view is loaded.
     */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set ProcessDelegates to be this object
        model.delegate = self
        model.tracker.delegate = self
        
        // Set initial values for variables in the model
        model.targetTempo = Float(metroStepper.value)
        model.checkWatchIsPaired()
        
        // Create Metronome object
        metro = Metronome(tempo: metroStepper.value)
        metro.isPlaying = false
    }
    
    /**
     Called when this view controller prepares to move to a new view controller.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Pass the TempoCalculator model to the destination view controllers
        if let destinationVC = segue.destination as? UITabBarController {
            if let tabVCs = destinationVC.viewControllers {
                (tabVCs[0] as! TempoViewController).model = self.model
                (tabVCs[1] as! MotionViewController).model = self.model
            }
        }
    }

}

