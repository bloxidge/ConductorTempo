//
//  InterfaceController.swift
//  ConductorTempo WatchKit Extension
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController, RecorderDelegate {
    
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var startStopButton: WKInterfaceButton!
    @IBOutlet var sendButton: WKInterfaceButton!
    @IBOutlet var fileLabel: WKInterfaceLabel!
    
    private var recorder = MotionRecorder()
    private let moss = UIColor(red: 0.0, green: 0.5, blue: 0.25, alpha: 1.0)
    private let cayenne = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
    
    var isFilePresent: Bool! {
        get {
            return self.isFilePresent
        }
        set {
            if newValue {
                sendButton.setAlpha(1.0)
                sendButton.setEnabled(true)
            } else {
                sendButton.setAlpha(0.6)
                sendButton.setEnabled(false)
            }
        }
    }
    var fileSize: String! {
        get {
            return self.fileSize
        }
        set {
            
            fileLabel.setText(newValue)
        }
    }
    
    @IBAction func startStopButtonPressed() {
        
        switch recorder.isRecording {
        case true:
            recorder.isRecording = false
            startStopButton.setTitle("Start")
            startStopButton.setBackgroundColor(moss)
            timer.stop()
        case false:
            recorder.isRecording = true
            startStopButton.setTitle("Stop")
            startStopButton.setBackgroundColor(cayenne)
            timer.setDate(Date(timeIntervalSinceNow: 0))
            timer.start()
        }
    }
    
    @IBAction func sendButtonPressed() {
        
        recorder.send()
    }
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        recorder.delegate = self
        recorder.checkIfFilePresent()
    }
    
    override func willActivate() {
        
        super.willActivate()
    }
    
    override func didDeactivate() {
        
        super.didDeactivate()
    }

}
