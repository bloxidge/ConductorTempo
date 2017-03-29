//
//  MotionRecorder.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import CoreMotion
import WatchConnectivity

class MotionRecorder: NSObject, WCSessionDelegate {
    
    var session: WCSession!
    var isRecording = false {
        didSet {
            switch isRecording {
            case true: start()
            case false: stop()
            }
        }
    }
    private let motionManager = CMMotionManager()
    private var currentRecording = [MotionDataPoint]()
    private let file = "motiondata.txt"
    private var url: URL!
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        motionManager.deviceMotionUpdateInterval = 0.02
        motionManager.startDeviceMotionUpdates()
    }
    
    private func start() {
        
        currentRecording.removeAll()
        
        var timestamp: TimeInterval = 0.0
        let startTime = Date(timeIntervalSinceNow: 0)
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
                (deviceMotion: CMDeviceMotion?, NSError) -> Void in
                
                timestamp = -startTime.timeIntervalSinceNow
                
                let acc = AccelerationPoint(x: Float(deviceMotion!.userAcceleration.x),
                                            y: Float(deviceMotion!.userAcceleration.y),
                                            z: Float(deviceMotion!.userAcceleration.z))
                let rot = RotationPoint(x: Float(deviceMotion!.rotationRate.x),
                                        y: Float(deviceMotion!.rotationRate.y),
                                        z: Float(deviceMotion!.rotationRate.z))
                let att = AttitudePoint(roll: Float(deviceMotion!.attitude.roll),
                                        pitch: Float(deviceMotion!.attitude.pitch),
                                        yaw: Float(deviceMotion!.attitude.yaw))
                
                self.currentRecording.append(MotionDataPoint(time: Float(timestamp),
                                                             acceleration: acc,
                                                             rotation: rot,
                                                             attitude: att))
            }
        }
    }
    
    private func stop() {
        
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        cleanMotionData()
        saveMotionData()
    }
    
    private func cleanMotionData() {
        
        var i = 1
        var prevTime: Float = 0.0
        
        for value in currentRecording {
            if (value.time - prevTime) < 0.01 {
                i += 1
            }
            prevTime = value.time
        }
        currentRecording.removeFirst(i)
        
        let initialTimestamp = currentRecording.first!.time
        for (index, _) in currentRecording.enumerated() {
            currentRecording[index].time -= initialTimestamp
        }
    }
    
    private func saveMotionData() {
        
        let data = Data(bytes: currentRecording, count: currentRecording.count * MemoryLayout<MotionDataPoint>.size)
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            url = dir.appendingPathComponent(file)
            try? data.write(to: url)
        }
    }
    
    func send() {
        
        session.transferFile(url, metadata: nil)
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}
