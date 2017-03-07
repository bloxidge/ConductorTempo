//
//  SignalProcessor.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 04/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Accelerate

class SignalProcessor {
    
    class func interp(sampleTimes: [Float], outputTimes: [Float], data: inout [Float]) -> [Float] {
        
        var b = calculateB(sampleTimes, outputTimes)
        
        var c = [Float](repeating: 0, count: b.count)
        vDSP_vlint(&data, &b, 1, &c, 1, UInt(b.count), UInt(data.count))
        
        return c
    }
    
    private class func calculateB(_ sampleTimes: [Float], _ outputTimes: [Float]) -> [Float] {
        
//        print(sampleTimes, outputTimes)
        
        var i = 0
        
//        print("sampleTimes size: \(sampleTimes.count)")
//        print("outputTimes size: \(outputTimes.count)")
        
        return outputTimes.map { (time: Float) -> Float in
            defer {
                if time > sampleTimes[i] { i += 1 }
            }
//            print(i, b, k, "\n")
//            k+=1
            return Float(i) + (time - sampleTimes[i]) / (sampleTimes[i+1] - sampleTimes[i])
        }
    }
    
}
