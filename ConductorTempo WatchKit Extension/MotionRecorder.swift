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
    private var startTime = TimeInterval()
    private let fs: Float = 50.0
    private let motionManager = CMMotionManager()
    private var currentRecording = [MotionDataPoint]()
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        motionManager.deviceMotionUpdateInterval = Double(1/fs)
        motionManager.startDeviceMotionUpdates()
    }
    
    private func start() {
        
        var timestamp: Float = 0.0
        
        currentRecording.removeAll()
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {
                (deviceMotion: CMDeviceMotion?, NSError) -> Void in
                
                let acc = AccelerationPoint(x: Float(deviceMotion!.userAcceleration.x),
                                            y: Float(deviceMotion!.userAcceleration.y),
                                            z: Float(deviceMotion!.userAcceleration.z))
                let rot = RotationPoint(x: Float(deviceMotion!.rotationRate.x),
                                        y: Float(deviceMotion!.rotationRate.y),
                                        z: Float(deviceMotion!.rotationRate.z))
                let att = AttitudePoint(roll: Float(deviceMotion!.attitude.roll),
                                        pitch: Float(deviceMotion!.attitude.pitch),
                                        yaw: Float(deviceMotion!.attitude.yaw))
                
                self.currentRecording.append(MotionDataPoint(time: round(2*self.fs * timestamp) / (2*self.fs),
                                                             acceleration: acc,
                                                             rotation: rot,
                                                             attitude: att))
                timestamp += 0.02
            }
        }
    }
    
    private func stop() {
        
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func send() {
        
        let data = Data(bytes: currentRecording, count: currentRecording.count * MemoryLayout<MotionDataPoint>.size)
        
        session.sendMessageData(data, replyHandler: nil, errorHandler: {(error) -> Void in
            print("WCSession errors have occurred: \(error.localizedDescription)")
        })
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}
