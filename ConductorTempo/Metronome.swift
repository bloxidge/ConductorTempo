//
//  Metronome.swift
//  ConductorTempo
//
//  Created by Y0075205 on 01/04/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import Foundation
import AudioKit

/**
 Class that contains the instructions for creating an AudioKit-powered Metronome object.
 */
class Metronome {
    
    // Private variables
    private let tickSound = AKSampler()
    private var metroTimer    : Timer!
    private var metroInterval : TimeInterval!
    
    // Public variables
    var tempo : Double! {
        get {
            return self.tempo
        }
        set {
            updateTempo(to: newValue)
        }
    }
    var isPlaying : Bool = false {
        didSet {
            if isPlaying {
                start()
            } else {
                stop()
            }
        }
    }
    
    /**
     Initialises the Metronome object.
     */
    init(tempo: Double) {
        
        self.tempo = tempo
        
        // Load metronome click sound and start AudioKit engine
        try! tickSound.loadWav("Click")
        AudioKit.output = tickSound
        AudioKit.start()
    }
    
    /**
     Start playing the metronome click.
     */
    private func start() {
        
        if isPlaying {
            metroTimer = Timer.scheduledTimer(timeInterval: metroInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
            metroTimer.fire()
        }
    }
    
    /**
     Stop playing the metronome click.
     */
    private func stop() {
        
        if metroTimer != nil {
            metroTimer.invalidate()
            metroTimer = nil
        }
    }
    
    /**
     Updates the metronome timer interval according to new tempo.
     */
    private func updateTempo(to tempo: Double) {
        
        stop()
        metroInterval = TimeInterval(60.0 / tempo)
        start()
    }
    
    /**
     Called by the metronome timer to trigger the sound sample.
     */
    @objc private func tick() {
        
        tickSound.play()
    }
}
