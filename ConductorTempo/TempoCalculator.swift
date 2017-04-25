//
//  TempoCalculator.swift
//  ConductorTempo
//
//  Created by Y0075205 on 04/03/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

import Foundation
import Surge
import Charts
import KalmanFilter
import WatchConnectivity

/**
 Delegate for updating current process information in the MainViewController.
 */
protocol ProcessDelegate  {
    
    var text          : String { get set }
    var inProgress    : Bool   { get set }
    var buttonEnabled : Bool   { get set }
    var tempo         : Float? { get set }
    var accuracy      : Float? { get set }
    
    func removeRefreshButton()
}

/**
 Class that contains the model for the main MVC. Contains all methods for receiving and processing the motion data.
 */
class TempoCalculator: NSObject, WCSessionDelegate {
    
    // Private variables
    private var session       : WCSession!
    private var motionData    : [MotionDataPoint]!
    private var motionVectors : MotionVectors!
    private var beats         : [Float]!
    private var localTempo    : [Float]!
    private var localAccuracy : [Float]!
    private var avgTempo      : Float!
    private var avgAccuracy   : Float!
    
    // Public variables
    var tracker = BeatTracker()
    var delegate : ProcessDelegate!
    var targetTempo : Float! {
        didSet {
            if avgTempo != nil {
                calculateAccuracy()
            }
        }
    }
    
    /**
     Initialises the TempoCalculator object.
     */
    override init() {
        
        super.init()
        
        // Check device supports Apple Watch then activate WCSession
        if WCSession.isSupported() {
            session = .default()
            session.delegate = self
            session.activate()
        }
        clearPendingTransfers()
    }
    
    /**
     Checks if Apple Watch is paired and watch app is installed. Updates message text accordingly.
     */
    func checkWatchIsPaired() {
        
        if session.isPaired && session.isWatchAppInstalled {
            delegate.text = "Apple Watch connected! \nYou currently have no saved data. \nStart recording on Apple Watch."
            delegate.removeRefreshButton()
        } else {
            delegate.text = "Communication unsuccesful... \nPlease check Apple Watch is paired and app is installed."
        }
    }
    
    /**
     Clears the WCSession transfer queue of any pending transfers.
     */
    private func clearPendingTransfers() {
        
        let transfers = session.outstandingFileTransfers
        if transfers.count > 0 {
            transfers.first!.cancel()
        }
    }
    
    /**
     WCSessionDelegate method. Called when a file is received successfully.
     */
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        checkWatchIsPaired()
        
        // Update message text and disable button to view graphs
        delegate.text = "Recording received!"
        delegate.buttonEnabled = false
        delegate.inProgress = true
        
        // Save data file to array of motion vectors
        if let rcvdData = try? Data(contentsOf: file.fileURL) {
            motionData = rcvdData.toArray(type: MotionDataPoint.self)
        }
        // Delete the transferred data file
        try? FileManager.default.removeItem(at: file.fileURL)
        
        processRecordingData()
    }
    
    /**
     Class that contains the top-level processing methods for calculating local tempo and accuracy.
     */
    private func processRecordingData() {
        
        // Create vector arrays and perform beat detection
        delegate.text = "Finding beats..."
        motionVectors = MotionVectors(from: motionData)
        beats = tracker.calculateBeats(from: motionVectors)
        
        // Calculate local tempo from inter-onset intervals
        delegate.text = "Inter-Onset Intervals..."
        let iois = differential(beats)
        localTempo = Float(60.0) / iois
        
        // Implement Kalman filter to smooth local tempo results
        delegate.text = "Filtering..."
        filterTempo()
        
        // Calculate average accuracy compared to target tempo
        delegate.text = "Accuracy..."
        calculateAccuracy()
        
        // Update message text and enable button to view graphs
        delegate.text = "Processing complete! \nStart new recording on Apple Watch when ready..."
        delegate.inProgress = false
        delegate.buttonEnabled = true
    }
    
    /**
     Smooths the local tempo results through a Kalman filter.
     */
    private func filterTempo() {
        
        var filter = KalmanFilter(stateEstimatePrior: mean(localTempo), errorCovariancePrior: 1)
        
        // Recursive filtering of local tempo values improving the filter with each pass
        for (i, value) in localTempo.enumerated() {
            let prediction = filter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0.07)
            localTempo[i] = Float(prediction.stateEstimatePrior)
            let update = prediction.update(measurement: value, observationModel: 1, covarienceOfObservationNoise: 1.5)
            filter = update
        }
        
        // Update average tempo value on the screen
        avgTempo = mean(localTempo)
        delegate.tempo = avgTempo
    }
    
    /**
     Calculates the accuracy of the local tempo compared to the target tempo.
     */
    private func calculateAccuracy() {
        
        localAccuracy = [Float]()
        localAccuracy.reserveCapacity(localTempo.count)
        localAccuracy.removeAll()
        
        // Accuracy calculation for each tempo value
        for value in localTempo {
            let diff = abs(targetTempo - value)
            var ratio = diff/value
            if ratio > 1 {
                ratio = 1
            }
            let accuracy: Float = (1 - ratio) * 100
            localAccuracy.append(accuracy)
        }
        
        // Update average accuracy value on the screen
        avgAccuracy = mean(localAccuracy)
        delegate.accuracy = avgAccuracy
    }
    
    /**
     Update the Local Tempo chart with the current data.
     */
    func updateTempoChart(_ chart: LineChartView) {
        
        var dataEntries = [ChartDataEntry]()
        var dataSets    = [LineChartDataSet]()
        var dataSet     = LineChartDataSet()
        
        // Line chart for local tempo
        for (i, value) in localTempo.enumerated() {
            let entry = ChartDataEntry(x: Double(beats[i]), y: Double(value))
            dataEntries.append(entry)
        }
        
        dataSet = LineChartDataSet(values: dataEntries, label: "Measured Tempo")
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.colors = [.aqua]
        dataSets.append(dataSet)
        
        dataEntries.removeAll()
        
        // Straight line showing target tempo
        let first = ChartDataEntry(x: Double(beats.first!), y: Double(targetTempo))
        let last  = ChartDataEntry(x: Double(beats.last!) , y: Double(targetTempo))
        dataEntries.append(contentsOf: [first, last])
        
        dataSet = LineChartDataSet(values: dataEntries, label: "Target Tempo")
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.lineDashLengths = [6.0]
        dataSet.lineDashPhase = 3.0
        dataSet.colors = [.purple]
        dataSets.append(dataSet)
        
        dataEntries.removeAll()
        
        // Set chart properties and update chart data
        let lineData = LineChartData(dataSets: dataSets)
        chart.chartDescription?.text = ""
        chart.xAxis.labelPosition = .bottom
        chart.leftAxis.axisMinimum = Double(targetTempo - 20)
        chart.leftAxis.axisMaximum = Double(targetTempo + 20)
        chart.rightAxis.enabled = false
        chart.legend.position = .aboveChartRight
        chart.legend.form = .line
        chart.data = lineData
    }
    
    /**
     Update the Motion Data chart with the current data. The displayed sensor data depends on the selected segment from the view controller.
     */
    func updateMotionChart(_ chart: LineChartView, selectedSegment: Int) {
        
        var dataEntries = [ChartDataEntry]()
        var dataSets    = [LineChartDataSet]()
        var dataSet     = LineChartDataSet()
        var vectors     = [[Float]]()
        var labels : [String]
        let colors : [UIColor] = [.red, .clover, .blue, .orange]
        
        // Selects the chosen sensor data to display
        switch selectedSegment {
        case 1:
            vectors = [motionVectors!.rotation.x, motionVectors!.rotation.y, motionVectors!.rotation.z]
            labels = ["X", "Y", "Z"]
            chart.chartDescription?.text = "Rotation"
        case 2:
            vectors = [motionVectors!.attitude.w, motionVectors!.attitude.x, motionVectors!.attitude.y, motionVectors!.attitude.z]
            labels = ["W", "X", "Y", "Z"]
            chart.chartDescription?.text = "Attitude"
        default:
            vectors = [motionVectors!.acceleration.x, motionVectors!.acceleration.y, motionVectors!.acceleration.z]
            labels = ["X", "Y", "Z"]
            chart.chartDescription?.text = "Accelerometer"
        }
        
        // Set chart properties and update chart data
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
        
        // Beat position data marked as circles on the zero-crossing of the X axis
//        for beat in beats {
//            let entry = ChartDataEntry(x: Double(beat), y: 0)
//            dataEntries.append(entry)
//        }
//        let beatData = LineChartDataSet(values: dataEntries, label: "Beats")
//        beatData.colors = [.magenta]
//        beatData.circleColors = [.magenta]
//        dataSets.append(beatData)
        
        // Set chart properties and update chart data
        let lineData = LineChartData(dataSets: dataSets)
        chart.chartDescription?.text = ""
        chart.xAxis.labelPosition = .bottom
//        chart.leftAxis.drawLabelsEnabled = false
//        chart.rightAxis.drawLabelsEnabled = false
        chart.legend.position = .aboveChartRight
        chart.data = lineData
    }
    
    // WCSessionDelegate required functions
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

}
