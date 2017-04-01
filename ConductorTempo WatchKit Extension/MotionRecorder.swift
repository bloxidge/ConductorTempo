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

protocol RecorderDelegate {
    
    var isFilePresent: Bool! { get set }
    var fileSize: String! { get set }
}

class MotionRecorder: NSObject, WCSessionDelegate {
    
    var delegate: RecorderDelegate!
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
    private let manager = FileManager.default
    private let file = "motiondata.txt"
    private var url: URL {
        get {
            let dir = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            return dir.appendingPathComponent(file)
        }
    }
    private var fileExists: Bool {
        get {
            return manager.fileExists(atPath: url.path)
        }
    }
    
    override init() {
        
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        deleteFile()
        
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
        
        try? data.write(to: url)
        
        checkIfFilePresent()
        delegate.fileSize = fileSizeString(for: data)
    }
    
    func checkIfFilePresent() {
        
        delegate.isFilePresent = fileExists
    }
    
    private func deleteFile() {
        
        if fileExists {
            try? manager.removeItem(at: url)
        }
    }
    
    private func fileSizeString(for data: Data) -> String {
        
        var bytes = Double(data.count)
        var i = 0
        let tokens = ["bytes", "Kb", "Mb", "Gb"]
        while bytes > 1024 {
            bytes /= 1024
            i += 1
        }
        return String(format: "%4.1f %@", bytes, tokens[i])
    }
    
    func send() {
        
        session.transferFile(url, metadata: nil)
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}
