//
//  InterfaceController.swift
//  ConductorTempo WatchKit Extension
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var startStopButton: WKInterfaceButton!
    @IBOutlet var sendBution: WKInterfaceButton!
    
    private var recorder = MotionRecorder()
    
    @IBAction func startStopButtonPressed() {
        
        switch recorder.isRecording {
        case true:
            recorder.isRecording = false
            startStopButton.setTitle("Start")
            timer.stop()
        case false:
            recorder.isRecording = true
            startStopButton.setTitle("Stop")
            timer.setDate(Date(timeIntervalSinceNow: 0))
            timer.start()
        }
    }
    
    @IBAction func sendButtonPressed() {
        
        recorder.send()
    }
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        
        super.willActivate()
    }
    
    override func didDeactivate() {
        
        super.didDeactivate()
    }

}
