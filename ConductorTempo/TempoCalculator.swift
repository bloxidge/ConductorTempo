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
import KalmanFilter
import WatchConnectivity

class TempoCalculator: NSObject, WCSessionDelegate {
    
    private var session: WCSession!
    private var motionData: [MotionDataPoint]!
    private var motionVectors: MotionVectors!
    var tracker = BeatTracker()
    var beats: [Float]!
    var localTempo, kalmanTempo: [Float]!
    
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
        
        /* Create vector arrays and perform beat detection */
        motionVectors = MotionVectors(from: motionData)
        beats = tracker.calculateBeats(from: motionVectors)
        
        /* Calculate local tempo from inter-onset intervals */
        let iois = differential(beats)
        localTempo = Float(60.0) / iois
        kalmanTempo = localTempo
        
        /* Find global average tempo */
        let globalTempo = mean(localTempo)
        
        /* Implement Kalman filter to smooth local tempo results */
        var filter = KalmanFilter(stateEstimatePrior: globalTempo, errorCovariancePrior: 1)
        for (i, value) in localTempo.enumerated() {
            let prediction = filter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0)
            kalmanTempo[i] = Float(prediction.stateEstimatePrior)
            let update = prediction.update(measurement: value, observationModel: 1, covarienceOfObservationNoise: 0.1)
            filter = update
        }
    }
    
    func updateTempoChart(_ chart: LineChartView) {
        
        var dataEntries = [ChartDataEntry]()
        var dataSets = [ChartDataSet]()
        
        for (i, value) in localTempo.enumerated() {
            let entry = ChartDataEntry(x: Double(beats[i]), y: Double(value))
            dataEntries.append(entry)
        }
        
        var dataSet = LineChartDataSet(values: dataEntries, label: "Raw Tempo")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [.orange]
        dataSets.append(dataSet)
        
        dataEntries.removeAll()
        
        for (i, value) in kalmanTempo.enumerated() {
            let entry = ChartDataEntry(x: Double(beats[i]), y: Double(value))
            dataEntries.append(entry)
        }
        
        dataSet = LineChartDataSet(values: dataEntries, label: "Kalman Filtered")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [.purple]
        dataSets.append(dataSet)
        
        let lineData = LineChartData(dataSets: dataSets)
        chart.chartDescription?.text = "Local Tempo Change"
        chart.setVisibleYRangeMinimum(100, axis: .left)
        chart.data = lineData
    }
    
    func updateMotionChart(_ chart: LineChartView, selectedSegment: Int) {
        
        var vectors = [[Float]]()
        var labels: [String]
        let colors: [UIColor] = [.red, .green, .blue]
        var dataEntries = [ChartDataEntry]()
        var dataSets = [LineChartDataSet]()
        var dataSet = LineChartDataSet()
        
        switch selectedSegment {
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
