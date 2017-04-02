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
    
    var tracker = BeatTracker()
    var delegate: ProcessDelegate!
    private var session: WCSession!
    private var motionData: [MotionDataPoint]!
    private var motionVectors: MotionVectors!
    private var beats, localTempo: [Float]!
    private var localAccuracy = [Float]()
    private var averageTempo, averageAccuracy: Float!
    var targetTempo: Float! {
        didSet {
            if averageTempo != nil {
                calculateAccuracy()
            }
        }
    }
    
    override init() {
        
        super.init()
        
        /* Check device supports Apple Watch then activate WCSession */
        if WCSession.isSupported() {
            session = .default()
            session.delegate = self
            session.activate()
        }
        clearPendingTransfers()
    }
    
    func checkWatchIsPaired() {
        
        /* Check if Watch is paired and app is installed */
        if session.isPaired && session.isWatchAppInstalled {
            delegate.text = "Apple Watch connected! \nYou currently have no saved data. \nStart recording on Apple Watch."
            delegate.removeRefreshButton()
        } else {
            delegate.text = "Communication unsuccesful... \nPlease check Apple Watch is paired and app is installed."
        }
    }
    
    private func clearPendingTransfers() {
        
        let transfers = session.outstandingFileTransfers
        if transfers.count > 0 {
            transfers.first!.cancel()
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        checkWatchIsPaired()
        
        delegate.text = "Recording received!"
        delegate.buttonEnabled = false
        delegate.inProgress = true
        
        if let rcvdData = try? Data(contentsOf: file.fileURL) {
            motionData = rcvdData.toArray(type: MotionDataPoint.self)
        }
        try? FileManager.default.removeItem(at: file.fileURL)
        
        processRecordingData()
    }
    
    private func processRecordingData() {
        
        /* Create vector arrays and perform beat detection */
        delegate.text = "Finding beats..."
        motionVectors = MotionVectors(from: motionData)
        beats = tracker.calculateBeats(from: motionVectors)
        
        /* Calculate local tempo from inter-onset intervals */
        delegate.text = "Inter-Onset Intervals..."
        let iois = differential(beats)
        localTempo = Float(60.0) / iois
        
        /* Implement Kalman filter to smooth local tempo results */
        delegate.text = "Filtering..."
        filterTempo()
        
        /* Calculate average accuracy compared to target tempo */
        delegate.text = "Accuracy..."
        calculateAccuracy()
        
        delegate.text = "Processing complete! \nStart new recording on Apple Watch when ready..."
        delegate.inProgress = false
        delegate.buttonEnabled = true
    }
    
    private func filterTempo() {
        
        var filter = KalmanFilter(stateEstimatePrior: mean(localTempo), errorCovariancePrior: 1)
        for (i, value) in localTempo.enumerated() {
            let prediction = filter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0.07)
            localTempo[i] = Float(prediction.stateEstimatePrior)
            let update = prediction.update(measurement: value, observationModel: 1, covarienceOfObservationNoise: 1.5)
            filter = update
        }
        averageTempo = mean(localTempo)
        delegate.tempo = averageTempo
    }
    
    private func calculateAccuracy() {
        
        localAccuracy.removeAll()
        for value in localTempo {
            let diff = abs(targetTempo - value)
            var ratio = diff/value
            if ratio > 1 {
                ratio = 1
            }
            let accuracy: Float = (1 - ratio) * 100
            localAccuracy.append(accuracy)
        }
        averageAccuracy = mean(localAccuracy)
        delegate.accuracy = averageAccuracy
    }
    
    func updateTempoChart(_ chart: LineChartView) {
        
        var dataEntries = [ChartDataEntry]()
        
        for (i, value) in localTempo.enumerated() {
            let entry = ChartDataEntry(x: Double(beats[i]), y: Double(value))
            dataEntries.append(entry)
        }
        
        let dataSet = LineChartDataSet(values: dataEntries, label: "Local Tempo")
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [.aqua]
        
        dataEntries.removeAll()
        
        let lineData = LineChartData(dataSet: dataSet)
        chart.chartDescription?.text = ""
        chart.xAxis.labelPosition = .bottom
        chart.leftAxis.axisMinimum = Double(averageTempo - 20)
        chart.leftAxis.axisMaximum = Double(averageTempo + 20)
        chart.rightAxis.drawLabelsEnabled = false
        chart.legend.position = .aboveChartRight
        chart.legend.form = .line
        chart.data = lineData
    }
    
    func updateMotionChart(_ chart: LineChartView, selectedSegment: Int) {
        
        var vectors = [[Float]]()
        var labels: [String]
        let colors: [UIColor] = [.red, .clover, .blue]
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
            dataSet.drawValuesEnabled = false
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
        chart.chartDescription?.text = ""
        chart.xAxis.labelPosition = .bottom
        chart.leftAxis.drawLabelsEnabled = false
        chart.rightAxis.drawLabelsEnabled = false
        chart.legend.position = .aboveChartRight
        chart.data = lineData
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

}
