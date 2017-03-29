//
//  TempoCalculator.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 04/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Surge
import Charts
import WatchConnectivity

class TempoCalculator: NSObject, WCSessionDelegate {
    
    private var session: WCSession!
    private var motionData: [MotionDataPoint]!
    private var motionVectors: MotionVectors!
    var tracker = BeatTracker()
    var beats: [Float]!
    
    override init() {
        
        super.init()
        
        checkWatchIsPaired()
    }
    
    private func checkWatchIsPaired() {
        
        if WCSession.isSupported() {
            session = .default()
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        if let rcvdData = try? Data(contentsOf: file.fileURL!) {
            motionData = rcvdData.toArray(type: MotionDataPoint.self)
        }
        processRecordingData()
    }
    
    private func processRecordingData() {
        
        motionVectors = MotionVectors(from: motionData)
        beats = tracker.calculateBeats(from: motionVectors)
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
        beatData.colors = [.magenta]
        beatData.circleColors = [.magenta]
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
