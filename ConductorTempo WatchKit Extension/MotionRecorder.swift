//
//  MotionRecorder.swift
//  ConductorTempo
//
//  Created by Y0075205 on 23/02/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import Foundation
import CoreMotion
import WatchConnectivity

/**
 Delegate for updating file information in the InterfaceController.
 */
protocol RecorderDelegate {
    
    var isFilePresent : Bool!   { get set }
    var fileSize      : String! { get set }
}

/**
 Class for creating a new MotionRecorder object. Contains the methods for recording and transferring Apple Watch motion sensor data.
 */
class MotionRecorder: NSObject, WCSessionDelegate {
    
    // Constants
    private let manager = FileManager.default
    private let file = "motiondata.txt"
    private let motionManager = CMMotionManager()
    
    // Private variables
    private var currentRecording = [MotionDataPoint]()
    private var url : URL {
        get {
            let dir = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            return dir.appendingPathComponent(file)
        }
    }
    private var fileExists : Bool {
        get {
            return manager.fileExists(atPath: url.path)
        }
    }
    
    // Public variables
    var delegate : RecorderDelegate!
    var session  : WCSession!
    var isRecording = false {
        didSet {
            switch isRecording {
            case true: start()
            case false: stop()
            }
        }
    }
    
    /**
     Initialises the MotionRecorder object.
     */
    override init() {
        
        super.init()
        
        // Set up and activate WatchConnectivity session
        if WCSession.isSupported() {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        // Remove previously saved recording on start
        deleteFile()
        
        // Set interval and start CoreMotion operation
        motionManager.deviceMotionUpdateInterval = 0.02
        motionManager.startDeviceMotionUpdates()
    }
    
    /**
     Start motion data recording.
     */
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
//                let euler = self.quaternionToEuler(deviceMotion!.attitude.quaternion)
                let att = AttitudePoint(w: Float(deviceMotion!.attitude.quaternion.w),
                                        x: Float(deviceMotion!.attitude.quaternion.x),
                                        y: Float(deviceMotion!.attitude.quaternion.y),
                                        z: Float(deviceMotion!.attitude.quaternion.z))
                
                self.currentRecording.append(MotionDataPoint(time: Float(timestamp),
                                                             acceleration: acc,
                                                             rotation: rot,
                                                             attitude: att))
            }
        }
    }
    
    /**
     Convert Quaternion attitude values to Euler angles.
     */
    private func quaternionToEuler(_ q: CMQuaternion) -> (roll: Double, pitch: Double, yaw: Double) {
        
        let roll  = atan2(2*q.y*q.w - 2*q.x*q.z, 1 - 2*q.y*q.y - 2*q.z*q.z)
        let pitch = atan2(2*q.x*q.w - 2*q.y*q.z, 1 - 2*q.x*q.x - 2*q.z*q.z)
        let yaw   =  asin(2*q.x*q.y + 2*q.z*q.w)
        
        return (roll, pitch, yaw)
    }
    
    /**
     Stop motion data recording.
     */
    private func stop() {
        
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        cleanMotionData()
        saveMotionData()
    }
    
    /**
     Remove any erroneous data points from the start of the recording.
     */
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
    
    /**
     Store motion recording array in data file and update delegate information.
     */
    private func saveMotionData() {
        
        let data = Data(bytes: currentRecording, count: currentRecording.count * MemoryLayout<MotionDataPoint>.size)
        
        try? data.write(to: url)
        
        checkIfFilePresent()
        delegate.fileSize = fileSizeString(for: data)
    }
    
    /**
     Start motion data recording.
     */
    func checkIfFilePresent() {
        
        delegate.isFilePresent = fileExists
    }
    
    /**
     Remove file if a file exists in the filesystem.
     */
    private func deleteFile() {
        
        if fileExists {
            try? manager.removeItem(at: url)
        }
    }
    
    /**
     Return formatted string of file size from raw data bytes.
     */
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
    
    /**
     Transfer file to phone app.
     */
    func send() {
        
        session.transferFile(url, metadata: nil)
    }
    
    /**
     Required function for WCSessionDelegate. Called when session has completed activation.
     */
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}
