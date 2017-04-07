//
//  InterfaceController.swift
//  ConductorTempo WatchKit Extension
//
//  Created by Y0075205 on 23/02/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import WatchKit
import Foundation

/**
 Class for the main interface controller. Implements RecorderDelegate for updating file size information and button availability.
 */
class InterfaceController: WKInterfaceController, RecorderDelegate {
    
    // Interface variables
    @IBOutlet var timer           : WKInterfaceTimer!
    @IBOutlet var startStopButton : WKInterfaceButton!
    @IBOutlet var sendButton      : WKInterfaceButton!
    @IBOutlet var fileLabel       : WKInterfaceLabel!
    
    // Private variables
    private var recorder = MotionRecorder()
    
    // RecorderDelegate variables
    var isFilePresent : Bool! {
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
    var fileSize : String! {
        get {
            return self.fileSize
        }
        set {
            fileLabel.setText(newValue)
        }
    }
    
    /**
     Called when the 'Start'/'Stop' button is pressed.
     */
    @IBAction func startStopButtonPressed() {
        
        switch recorder.isRecording {
        case true:
            recorder.isRecording = false
            startStopButton.setTitle("Start")
            startStopButton.setBackgroundColor(.moss)
            timer.stop()
        case false:
            recorder.isRecording = true
            startStopButton.setTitle("Stop")
            startStopButton.setBackgroundColor(.cayenne)
            timer.setDate(Date(timeIntervalSinceNow: 0))
            timer.start()
        }
    }
    
    /**
     Called when the 'Send' button is pressed.
     */
    @IBAction func sendButtonPressed() {
        
        recorder.send()
    }
    
    // Interface Controller required functions
    
    /**
     Called when this interface is loaded.
     */
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
