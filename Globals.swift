//
//  Globals.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 24/02/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation

struct MotionDataPoint: CustomStringConvertible {
    
    let time: Float
    let acceleration: AccelerationPoint
    let rotation: RotationPoint
    let attitude: AttitudePoint
    
    var description: String {
        return "\n\(time): \(acceleration) \(rotation) \(attitude)"
    }
}

struct AccelerationPoint: CustomStringConvertible {
    
    let x: Float
    let y: Float
    let z: Float
    
    var description: String {
        return "[\(x) \(y) \(z)]"
    }
}

struct RotationPoint: CustomStringConvertible {
    
    let x: Float
    let y: Float
    let z: Float
    
    var description: String {
        return "[\(x) \(y) \(z)]"
    }
}

struct AttitudePoint: CustomStringConvertible {
    
    let roll: Float
    let pitch: Float
    let yaw: Float
    
    var description: String {
        return "[\(roll) \(pitch) \(yaw)]"
    }
}

struct MotionVectors: CustomStringConvertible {
    
    var time = [Float]()
    var acceleration = AccelerationVectors()
    var rotation = RotationVectors()
    var attitude = AttitudeVectors()
    
    var description: String {
        
        var desc = String()
        
        for (index, t) in time.enumerated() {
            desc.append("\(t): [\(acceleration.x[index]) \(acceleration.y[index]) \(acceleration.z[index])] [\(rotation.x[index]) \(rotation.y[index]) \(rotation.z[index])] [\(attitude.roll[index]) \(attitude.pitch[index]) \(attitude.yaw[index])]\n")
        }
        return desc
    }
    
    init(from motionData: [MotionDataPoint]) {
        
        for dataPoint in motionData {
            time.append(dataPoint.time)
            acceleration.x.append(dataPoint.acceleration.x)
            acceleration.y.append(dataPoint.acceleration.y)
            acceleration.z.append(dataPoint.acceleration.z)
            rotation.x.append(dataPoint.rotation.x)
            rotation.y.append(dataPoint.rotation.y)
            rotation.z.append(dataPoint.rotation.z)
            attitude.roll.append(dataPoint.attitude.roll)
            attitude.pitch.append(dataPoint.attitude.pitch)
            attitude.yaw.append(dataPoint.attitude.yaw)
        }
    }
    
    struct AccelerationVectors: CustomStringConvertible {
        
        var x = [Float]()
        var y = [Float]()
        var z = [Float]()
        
        var description: String {
            
            var desc = String()
            
            for (index, _) in x.enumerated() {
                desc.append("[\(x[index]) \(y[index]) \(z[index])]\n")
            }
            return desc
        }
    }

    struct RotationVectors: CustomStringConvertible {
        
        var x = [Float]()
        var y = [Float]()
        var z = [Float]()
        
        var description: String {
            
            var desc = String()
            
            for (index, _) in x.enumerated() {
                desc.append("[\(x[index]) \(y[index]) \(z[index])]\n")
            }
            return desc
        }
    }

    struct AttitudeVectors: CustomStringConvertible {
        
        var roll = [Float]()
        var pitch = [Float]()
        var yaw = [Float]()
        
        var description: String {
            var desc = String()
            
            for (index, _) in roll.enumerated() {
                desc.append("[\(roll[index]) \(pitch[index]) \(yaw[index])]\n")
            }
            return desc
        }
    }
}

extension Data {
    
    init<T>(fromArray values: [T]) {
        var values = values
        self.init(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }
    
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
        }
    }
}
