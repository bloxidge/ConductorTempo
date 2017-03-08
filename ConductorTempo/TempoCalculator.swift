//
//  TempoCalculator.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 04/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Accelerate
import Charts
import WatchConnectivity

class TempoCalculator: NSObject, WCSessionDelegate {
    
    private var session: WCSession!
    private var motionData: [MotionDataPoint]!
//    private var recordingArray = [[MotionDataPoint]]()
    private var motionVectors, upsampledVectors: MotionVectors!
    private var detector = BeatDetector()
    private var beats: [Float]!
    
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
        
        upsampledVectors = resample(motionVectors, fs: 8000)
        beats = detector.calculateBeats(data: upsampledVectors.acceleration.z)
        print(beats)
    }
    
    private func resample(_ input: MotionVectors, fs: Float) -> MotionVectors {
        
        var output = input
        var time = [Float]()
        var t: Float = 0.0
        while t < input.time[input.time.count - 2] {
            t = round(2*fs * t) / (2*fs)
            time.append(t)
            t += 1/fs
        }
        
        output.time = time
        
        output.acceleration.x = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.x)
        output.acceleration.y = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.y)
        output.acceleration.z = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.z)
        
        output.rotation.x = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.x)
        output.rotation.y = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.y)
        output.rotation.z = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.z)
        
        output.attitude.roll = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.roll)
        output.attitude.pitch = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.pitch)
        output.attitude.yaw = Resampler.interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.yaw)
        
        return output
    }
    
    func update(chart: LineChartView, from segment: UISegmentedControl) {
        
        var vectors = [[Float]]()
        var labels: [String]
        let colors: [UIColor] = [.red, .green, .blue]
        var dataEntries = [ChartDataEntry]()
        var dataSets = [LineChartDataSet]()
        var dataSet = LineChartDataSet()
        
        switch segment.selectedSegmentIndex {
        case 1:
            vectors = [motionVectors!.rotation.x, motionVectors!.rotation.y, motionVectors!.rotation.z]
            labels = ["X", "Y", "Z"]
            chart.chartDescription?.text = "Rotation"
        case 2:
            vectors = [motionVectors!.attitude.roll, motionVectors!.attitude.pitch, motionVectors!.attitude.yaw]
            labels = ["Roll", "Pitch", "Yaw"]
            chart.chartDescription?.text = "Attitude"
        default:
            vectors = [motionVectors!.acceleration.x, motionVectors!.acceleration.y, motionVectors!.acceleration.z]
            labels = ["X", "Y", "Z"]
            chart.chartDescription?.text = "Accelerometer"
        }
        
        for (index, vector) in vectors.enumerated() {
            
            for (i, value) in vector.enumerated() {
                let entry = ChartDataEntry(x: Double(motionVectors!.time[i]), y: Double(value))
                dataEntries.append(entry)
            }
            dataSet = LineChartDataSet(values: dataEntries, label: labels[index])
            dataSet.drawCirclesEnabled = false
            dataSet.lineWidth = 2.0
            dataSet.colors = [colors[index]]
            
            dataSets.append(dataSet)
            
            dataEntries.removeAll()
        }
        
        for beat in beats {
            let entry = ChartDataEntry(x: Double(beat), y: 0)
            dataEntries.append(entry)
        }
        let beatData = LineChartDataSet(values: dataEntries, label: "Beats")
        dataSets.append(beatData)
        
        let lineData = LineChartData(dataSets: dataSets)
        chart.data = lineData
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

}
