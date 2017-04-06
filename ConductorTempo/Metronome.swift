//
//  Metronome.swift
//  ConductorTempo
//
//  Created by Y0075205 on 01/04/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import Foundation
import AudioKit

class Metronome {
    
    private let tickSound = AKSampler()
    private var metroTimer: Timer!
    private var metroInterval: TimeInterval!
    var tempo: Double! {
        get {
            return self.tempo
        }
        set {
            updateTempo(to: newValue)
        }
    }
    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                start()
            } else {
                stop()
            }
        }
    }
    
    init(tempo: Double) {
        
        self.tempo = tempo
        
        try! tickSound.loadWav("Click")
        AudioKit.output = tickSound
        AudioKit.start()
    }
    
    private func start() {
        
        if isPlaying {
            metroTimer = Timer.scheduledTimer(timeInterval: metroInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
            metroTimer.fire()
        }
    }
    
    private func stop() {
        
        if metroTimer != nil {
            metroTimer.invalidate()
            metroTimer = nil
        }
    }
    
    private func updateTempo(to tempo: Double) {
        
        stop()
        metroInterval = TimeInterval(60.0 / tempo)
        start()
    }
    
    @objc private func tick() {
        
        tickSound.play()
    }
}
