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
    
    private var model = TempoCalculator()
    
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
            return self.inProgress
        }
    }
    
    @IBAction func returnToMainViewController(_ segue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        model.tracker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

}

