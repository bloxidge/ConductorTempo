//
//  TempoDetector.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 04/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Accelerate
import WatchConnectivity

class TempoDetector: NSObject, WCSessionDelegate {
    
    private var session: WCSession!
    private var motionData: [MotionDataPoint]!
    private var recordingArray = [[MotionDataPoint]]()
    var motionVectors: MotionVectors!
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        motionData = messageData.toArray(type: MotionDataPoint.self)
        motionVectors = MotionVectors(from: motionData)
        
        processRecordingData()
    }
    
    private func processRecordingData() {
        
        resampleMotionVectors(to: 3200)
    }
    
    private func resampleMotionVectors(to fs: Float) {
        
        var time = [Float]()
        var t: Float = 0.0
        while t < motionVectors.time[motionVectors.time.count - 2] {
            t = round(2*fs * t) / (2*fs)
            time.append(t)
            t += 1/fs
        }
        
        motionVectors.acceleration.x = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.x)
        motionVectors.acceleration.y = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.y)
        motionVectors.acceleration.z = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.z)
        
        motionVectors.rotation.x = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.x)
        motionVectors.rotation.y = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.y)
        motionVectors.rotation.z = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.z)
        
        motionVectors.attitude.roll = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.roll)
        motionVectors.attitude.pitch = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.pitch)
        motionVectors.attitude.yaw = Resampler.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.yaw)
        
        motionVectors.time = time
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

}
