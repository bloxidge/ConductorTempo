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
    var oldMotionVectors: MotionVectors!
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        print("\nAt the phone end...")
        print(messageData)
        
        motionData = messageData.toArray(type: MotionDataPoint.self)
        
//        print("\nReceived Data!")
//        print(motionData)
        
        motionVectors = MotionVectors(from: motionData)
        
//        print("\nProcessed Data!")
//        print(motionVectors)
        
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
//            print(t)
            time.append(t)
            t += 1/fs
        }
        
        oldMotionVectors = motionVectors
//        print("\nBefore")
//        print(oldMotionVectors)
        
        motionVectors.acceleration.x = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.x)
        motionVectors.acceleration.y = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.y)
        motionVectors.acceleration.z = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.acceleration.z)
        
        motionVectors.rotation.x = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.x)
        motionVectors.rotation.y = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.y)
        motionVectors.rotation.z = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.rotation.z)
        
        motionVectors.attitude.roll = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.roll)
        motionVectors.attitude.pitch = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.pitch)
        motionVectors.attitude.yaw = SignalProcessor.interp(sampleTimes: motionVectors.time, outputTimes: time, data: &motionVectors.attitude.yaw)
        
        motionVectors.time = time
        
//        print("\nAfter")
//        print(motionVectors)
        
    }

//    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
//
//        recordingArray = message["data"] as? [[MotionData]]
//
//        print("Data received!")
//
//    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //print(error?.localizedDescription)
    }

}
