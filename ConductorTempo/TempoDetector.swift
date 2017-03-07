//
//  TempoDetector.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 04/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Accelerate
import Charts
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
    
    func update(chart: LineChartView, from segment: UISegmentedControl) {
        
        var values = [[Float]]()
        var vector = [Float]()
        
        switch segment.selectedSegmentIndex {
        case 1:
            values = [motionVectors!.rotation.x, motionVectors!.rotation.y, motionVectors!.rotation.z]
            chart.chartDescription?.text = "Rotation"
        case 2:
            values = [motionVectors!.attitude.roll, motionVectors!.attitude.pitch, motionVectors!.attitude.yaw]
            chart.chartDescription?.text = "Attitude"
        default:
            values = [motionVectors!.acceleration.x, motionVectors!.acceleration.y, motionVectors!.acceleration.z]
            chart.chartDescription?.text = "Accelerometer"
        }
        
        var dataEntries = [ChartDataEntry]()
        var dataSets = [LineChartDataSet]()
        var dataSet = LineChartDataSet()
        
        vector = values[0]
        for (index, value) in vector.enumerated() {
            let entry = ChartDataEntry(x: Double(motionVectors!.time[index]), y: Double(value))
            dataEntries.append(entry)
        }
        dataSet = LineChartDataSet(values: dataEntries, label: "X")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [UIColor.red]
        dataSets.append(dataSet)
        dataEntries.removeAll()
        
        vector = values[1]
        for (index, value) in vector.enumerated() {
            let entry = ChartDataEntry(x: Double(motionVectors!.time[index]), y: Double(value))
            dataEntries.append(entry)
        }
        dataSet = LineChartDataSet(values: dataEntries, label: "Y")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [UIColor.green]
        dataSets.append(dataSet)
        dataEntries.removeAll()
        
        vector = values[2]
        for (index, value) in vector.enumerated() {
            let entry = ChartDataEntry(x: Double(motionVectors!.time[index]), y: Double(value))
            dataEntries.append(entry)
        }
        dataSet = LineChartDataSet(values: dataEntries, label: "Z")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [UIColor.blue]
        dataSets.append(dataSet)
        dataEntries.removeAll()
        
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
