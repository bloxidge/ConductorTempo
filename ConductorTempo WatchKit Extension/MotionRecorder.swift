//
//  MotionRecorder.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 23/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMotion
import WatchConnectivity

//protocol TimerDelegate: class {
//    
//    func updateTimerLabel(to time: (m: String, s: String, ms: String))
//}

class MotionRecorder: NSObject, WCSessionDelegate {
    
//    weak var delegate: TimerDelegate?
    var session: WCSession!
    
    var isRecording = false {
        didSet {
            switch isRecording {
            case true: start()
            case false: stop()
            }
        }
    }
//    private var timer = Timer()
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
        
        currentRecording.removeAll()
        
//        if !timer.isValid {
//            
//            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
//            startTime = Date.timeIntervalSinceReferenceDate
//        }
        
        var timestamp: Float = 0.0
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {
                (deviceMotion: CMDeviceMotion?, NSError) -> Void in
                
//                let stampedTime = Date.timeIntervalSinceReferenceDate - self.startTime
//                self.currentRecording.time.append(stampedTime)
//                
//                self.currentRecording.acceleration.x.append(deviceMotion!.userAcceleration.x)
//                self.currentRecording.acceleration.y.append(deviceMotion!.userAcceleration.y)
//                self.currentRecording.acceleration.z.append(deviceMotion!.userAcceleration.z)
//                self.currentRecording.rotation.x.append(deviceMotion!.rotationRate.x)
//                self.currentRecording.rotation.y.append(deviceMotion!.rotationRate.y)
//                self.currentRecording.rotation.z.append(deviceMotion!.rotationRate.z)
//                self.currentRecording.attitude.roll.append(deviceMotion!.attitude.roll)
//                self.currentRecording.attitude.pitch.append(deviceMotion!.attitude.pitch)
//                self.currentRecording.attitude.yaw.append(deviceMotion!.attitude.yaw)
                
                let acc = AccelerationPoint(x: Float(deviceMotion!.userAcceleration.x),
                                            y: Float(deviceMotion!.userAcceleration.y),
                                            z: Float(deviceMotion!.userAcceleration.z))
                let rot = RotationPoint(x: Float(deviceMotion!.rotationRate.x),
                                        y: Float(deviceMotion!.rotationRate.y),
                                        z: Float(deviceMotion!.rotationRate.z))
                let att = AttitudePoint(roll: Float(deviceMotion!.attitude.roll),
                                        pitch: Float(deviceMotion!.attitude.pitch),
                                        yaw: Float(deviceMotion!.attitude.yaw))
//                let stampedTime = Date.timeIntervalSinceReferenceDate - self.startTime)
                
//                if let firstValue = self.currentRecording.first {
//                    self.initialTimestamp = firstValue.time
//                } else {
//                    self.initialTimestamp = stampedTime
//                }
                
                self.currentRecording.append(MotionDataPoint(time: round(2*self.fs * timestamp) / (2*self.fs),
                                                         acceleration: acc,
                                                         rotation: rot,
                                                         attitude: att))
                timestamp += 0.02
            }
        }
    }
    
    private func stop() {
        
//      timer.invalidate()
        
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        
//        recordingArray.append(currentRecording)
    }
    
    func send() {
        
        print("\nAt the watch end...")
        
//        for (index, recording) in recordingArray.enumerated() {
        
            let data = Data(bytes: currentRecording, count: currentRecording.count * MemoryLayout<MotionDataPoint>.size)
//            print("#\(index+1): \(data)")
            
            session.sendMessageData(data, replyHandler: nil, errorHandler: {(error) -> Void in
                print("WCSession errors have occurred: \(error.localizedDescription)")
            })
//        }
//        let data = NSData(bytes: recordingArray, length: recordingArray.count * MemoryLayout<MotionData>.size)
        
//        session.sendMessage(["data" : recordingArray], replyHandler: nil, errorHandler: {(error) -> Void in
//            print("sendMessage errors have occured")
//            print(error.localizedDescription)
//        })
    }
    
//    private func saveRecording(_ array: NSArray) {
//        
//        let file = "MyData2.txt"
//        
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            
//            print("In the loop!")
//            
//            let url = dir.appendingPathComponent(file)
//            
//            print(url)
//            
//            array.write(toFile: url.path, atomically: true)
//            
//            do {
//                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
//                print(attributes[.size]!)
//            }
//            catch let error as NSError {
//                print(error)
//            }
//        }
//        
//        let filePath = NSTemporaryDirectory() + "MyData.txt"
//        let file: FileHandle? = FileHandle(forWritingAtPath: filePath)
//        file.
//        
//        print(file)
//        
//        if file != nil {
//            
//            print("In the loop!")
//            
//            let data = NSKeyedArchiver.archivedData(withRootObject: array)
//            file?.write(data)
//            file?.closeFile()
//            
//            print("File created!")
//            
//        }
//    }
    
//    @objc private func updateTimer() {
//        
//        let currentTime = Date.timeIntervalSinceReferenceDate
//        
//        // Find the difference between current time and start time.
//        var elapsedTime = currentTime - startTime
//        
//        // Calculate the minutes in elapsed time.
//        let minutes = UInt8(elapsedTime / 60.0)
//        elapsedTime -= (TimeInterval(minutes) * 60)
//        
//        // Calculate the seconds in elapsed time.
//        let seconds = UInt8(elapsedTime)
//        elapsedTime -= TimeInterval(seconds)
//        
//        // Calculate the milliseconds in elapsed time.
//        let milliseconds = UInt8(elapsedTime * 100)
//        
//        // Add the leading zero for minutes, seconds and millseconds and store them as string constants
//        let m = String(format: "%02d", minutes)
//        let s = String(format: "%02d", seconds)
//        let ms = String(format: "%02d", milliseconds)
//        
//        // Call delegate to update timer label in InterfaceController
//        self.delegate?.updateTimerLabel(to: (m, s, ms))
//    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}
