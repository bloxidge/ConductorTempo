//
//  BeatTracker.swift
//  ConductorTempo
//
//  Created by Y0075205 on 07/03/2017.
//  Copyright © 2017 Y0075205. All rights reserved.
//

/**************************************************
 *
 *  [1]  D. P. W. Ellis, “Beat Tracking by Dynamic Programming,” J. New Music Res., vol. 36, no. 1, pp. 51–60, 2007. [Online].
 *       Available: https://labrosa.ee.columbia.edu/projects/beattrack/
 *
 **************************************************/

import Foundation
import Surge

/**
 Class that contains the processing methods for calculating beat tracking from a set of input motion vectors.
 */
class BeatTracker {
    
    // Constants
    let newSampleRate   : Float = 8000
    let windowWidth     : Int = 256
    let numberOfMelBins : Int = 40
    private let windowHop        : Int = 32
    private let nyquistFrequency : Float = 4000
    private let tightness        : Float = 400
    private let oesr             : Float = 8000/32
    
    // Public variables
    var delegate: ProcessDelegate!
    
    // Structures
    private struct TempoData {
        var slow  : Float
        var fast  : Float
        var ratio : Float
    }
    
    /**
     Main public function: takes in recorded motion vectors and returns beat positions.
     */
    func calculateBeats(from vectors: MotionVectors) -> [Float] {
        
        // Create a new set of vectors at new sampling frequency
        delegate.text = "Resampling..."
        let newVecs = resample(vectors)
        
        // Pick vector to use for beat analysis
        let data = newVecs.attitude.w
        
        // Perform FFT that returns frequency bins on the 'mel' scale
        delegate.text = "Spectrum..."
        let bins = melSpectrumBins(data)
        
        // Calculate onset envelope from FFT data
        delegate.text = "Calculus..."
        let env = calculateOnsetEnvelope(bins)
        
        // Estimate two most likely starting tempos based on onset envelope
        delegate.text = "Estimation..."
        let tempo = estimateTempo(from: env)
        
        // Retrieve locations of beats by matching onset envelope with predicted onset times
        delegate.text = "Beats..."
        let beats = beatTracking(tempo, onsetEnvelope: env)
        
        return beats
    }
    
    /**
     Resamples the motion vector arrays from ~50Hz to approximately auditory new sampling frequency (8kHz).
     */
    private func resample(_ input: MotionVectors) -> MotionVectors {
        
        let fs = newSampleRate
        var output = input
        var time = [Float]()
        var t: Float = 0.0
        while t < input.time[input.time.count - 2] {
            t = round(fs * t) / fs
            time.append(t)
            t += 1/fs
        }
        
        output.time = time
        
        output.acceleration.x = interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.x)
        output.acceleration.y = interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.y)
        output.acceleration.z = interp(sampleTimes: input.time, outputTimes: output.time, data: input.acceleration.z)
        
        output.rotation.x = interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.x)
        output.rotation.y = interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.y)
        output.rotation.z = interp(sampleTimes: input.time, outputTimes: output.time, data: input.rotation.z)
        
        output.attitude.w = interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.w)
        output.attitude.x = interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.x)
        output.attitude.y = interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.y)
        output.attitude.z = interp(sampleTimes: input.time, outputTimes: output.time, data: input.attitude.z)
        
        return output
    }
    
    /**
     Perform a fourier transform on the data using a hanning window windowWidth and windowHop advance between frames.
     This is converted to an 'approximate auditory representation' by mapping the fft spectral bins onto 40 weighted Mel bands.
     Mel loosely stands for melody and is equal to the range of tones that are expected to be used most often for musical compositions.
     
     Adapted from Matlab script: `tempo2.m` [1]
     */
    private func melSpectrumBins(_ data: [Float]) -> [[Float]] {
        
        let weights = fft2mel()
        let hann = hanningWindow(windowWidth)
        let numberOfSamples = data.count
        let minus80dBs : Float = -78.7440522
        
        var bins : [[Float]] = []
        bins.reserveCapacity(numberOfSamples - windowWidth)
        
        var ftable : [Float] = []
        ftable.reserveCapacity(windowWidth)
        
        var i = 0
        while i < (numberOfSamples - windowWidth) {
            
            ftable = fft(mul(data[i ..< (i  + windowWidth)], y: hann)) // Fast fourier transform on array slice
            
            var D : [Float] = []
            D.reserveCapacity(numberOfMelBins)
            for j in 0 ..< numberOfMelBins { // From this construct the db-magnitude-mel spectrogram
                var product = summul(weights[j][0..<windowWidth], y: ftable)
                product = 20*log10(max(0.0000000001,product)) // in dBs
                if(product < minus80dBs) {
                    product = minus80dBs
                }
                D.append(product)
            }
            bins.append(D)
            i = i + windowHop
        }
        
        return bins
    }

    /**
     First order differentiation (dy/dx) along time is calculated for each bin, giving a one dimensional 'onset strength envelope' against time that responds to proportional increase in energy summed across approximately auditory frequency bins.
     
     Adapted from Matlab script: `tempo2.m` [1]
     */
    private func calculateOnsetEnvelope(_ array: [[Float]] ) -> [Float] {
        
        var decisionWaveform : [Float] = []
        decisionWaveform.reserveCapacity(array.count)
        for i in 0 ..< (array.count - 1) {
            var avg : Float = 0.0
            avg = mean(clip(sub(array[i + 1], y: array[i]), low: 0, high: FLT_MAX))
            decisionWaveform.append(avg)
        }
        
        // Need to remove DC component and smooth result
        // a(1)y(n)=b(1)x(n)+b(2)x(n−1)−a(2)y(n−1)
        // filter([1 -1], [1 -.99],mm)
        let x = decisionWaveform
        for j in 1 ..< decisionWaveform.count {
            decisionWaveform[j] = x[j] + (-1*x[j-1]) + (0.99*decisionWaveform[j-1])
        }
        
        return decisionWaveform
    }
    
    /**
     Global tempo estimation. Returns the top 2 BPM estimates; use faster one for beat tracking.
     
     Adapted from Matlab script: `tempo2.m` [1]
     */
    private func estimateTempo(from array: [Float]) -> TempoData {
        
        let maxd   : Float = 60
        let maxt   : Float = 120
        let acmax  : Int = Int(round(4*oesr));
        let maxcol : Int = min(Int(round(maxt*oesr)),array.count)
        let mincol : Int = max(0, Int(maxcol-Int(round(maxd*oesr))))
        
        // Only use the 1st 90 sec to estimate global pd
        let xcr = xcorr(Array(array[mincol ..< maxcol]), max: acmax)
        
        // Get the latter half of the xcr
        var rawxcr = Array(xcr[acmax..<xcr.count])
        
        // Rather than strictly using the raw output from the autocorrlation the algorithm uses a gaussian distribution around 120bpm which due to human psychology is the most likely beat time for a given song. This greatly improves the performance of the algorithm!
        var xcrwin : [Float] = []
        xcrwin.reserveCapacity(acmax)
        for i in 0 ..< acmax {
            let beatsPerMilisecond : Float = (60 * oesr) / (Float(i+1) + 0.1)
            let tmean : Float = 240
            let tsd : Float = 1.0
            xcrwin.append(exp ( -0.5 * ( pow( (log(beatsPerMilisecond/tmean)/log(2)/tsd) , 2))))
        }
        rawxcr = mul(rawxcr , y: xcrwin)
        
        var xcr00 = rawxcr
        xcr00.append(0)
        xcr00.insert(0, at: 0) // rawxcr padded with 2 zeros on either end
        
        let xcr2Size = Int(ceil(Double(rawxcr.count/2)))
        var xcr2 : [Float] = []
        xcr2.reserveCapacity(xcr2Size)
        for τ in 1 ..< 500 {
            let i = τ-1
            xcr2.append(xcr00[τ])
            xcr2[i] = xcr2[i] + 0.5*xcr00[2*τ]
            xcr2[i] = xcr2[i] + 0.25*xcr00[(2*τ) - 1]
            xcr2[i] = xcr2[i] + 0.25*xcr00[(2*τ) + 1]
        }
        
        let xcr3Size = Int(ceil(Double(rawxcr.count/3)))
        var xcr3 : [Float] = []
        xcr3.reserveCapacity(xcr3Size)
        for τ in 1 ..< 334 {
            let i = τ-1
            xcr3.append(xcr00[τ])
            xcr3[i] = xcr3[i] + 0.33*xcr00[3*τ]
            xcr3[i] = xcr3[i] + 0.33*xcr00[(3*τ) - 1]
            xcr3[i] = xcr3[i] + 0.33*xcr00[(3*τ) + 1]
        }
        
        var startpd  : Int = 0
        var startpd2 : Int = 0
        
        if max(xcr2) > max(xcr3) {
            startpd = maxIndex(xcr2)
            startpd2 = startpd * 2
        }
        else {
            startpd = maxIndex(xcr3)
            startpd2 = startpd * 3
        }
        
        var tempo = TempoData(slow: 60.0/((Float(startpd))/oesr),
                              fast: 60.0/((Float(startpd2))/oesr),
                              ratio: rawxcr[startpd]/(rawxcr[startpd]+rawxcr[startpd2]))
        
        // Reorders if it comes out the wrong way around
        if tempo.fast < tempo.slow {
            let fast = tempo.fast
            tempo.fast = tempo.slow
            tempo.slow = fast
        }
        
        return tempo
    }
    
    /**
     Returns the times (in sec) of the beats in the waveform from the onset envelope.
     
     Adapted from Matlab script: `beat2.m` [1]
     */
    private func beatTracking(_ tempo: TempoData, onsetEnvelope: [Float]) -> [Float] {
        
        var startBPM : Float = 0
        
        if tempo.ratio > 0.5 {
            startBPM = Float(tempo.fast) // Fast result from the autocorrelation
        } else {
            startBPM = Float(tempo.slow) // Slow result from the autocorrelation
        }
        let pd = (60*oesr)/startBPM // numbeats in onsetEnvelope step, probability there is a beat in each sampling interval
        let onsetEnv = onsetEnvelope / std(onsetEnvelope) // vector which maps change in frequency
        
        /* NOTE: Gaussian probability weighting function centered around 120bpm.
         This is the probability of the tempo of the song taken from experimental evidence */
        var gaussTempoProb : [Float] = []
        for i in Int(-pd) ..< Int(pd) {
            gaussTempoProb.append(-0.5 * pow((Float(i) / (pd/32)), 2))
        }
        gaussTempoProb = exp(gaussTempoProb)
        
        // LocalScore is a smoothed version of the onsetEnv based on the 120bpm window
        var localScore = conv(gaussTempoProb, onsetEnv)
        let sValue = Int(round(Double(gaussTempoProb.count/2)))
        let eValue = Int(onsetEnv.count)
        localScore = Array(localScore[sValue..<eValue])
        
        // Setting up some array variables for the next part
        var backLink : [Int] = Array(repeating: 0, count: localScore.count)
        var cScore   : [Float] = Array(repeating: 0.0, count: localScore.count)
        var prange   : [Int] = []; prange.reserveCapacity(512)
        var txwt     : [Float] = []; txwt.reserveCapacity(512)
        
        // Filling the arrays
        for i in Int(round(-2*pd)) ..< Int(-round(pd/2)) {
            prange.append(i)
            txwt.append(abs(pow(log(Float(i) / -pd), 2)) * -tightness)
        }
        
        // This creates a recursive estimation of each beat interval
        var starting = true
        for i in 0 ..< localScore.count {
            let timeRange_start = Int(round(-2*pd)) + i
            let zpad : Int = max(0, min(-timeRange_start, prange.count))
            var scorecands = txwt
            var index = 0
            for j in zpad ..< prange.count {
                scorecands[index] = scorecands[index] + cScore[timeRange_start + j]
                index += 1
            }
            cScore[i] = max(scorecands) + localScore[i]
            if (starting && localScore[i] < (0.01 * max(localScore))) {
                backLink[i] = -1;
            }
            else {
                backLink[i] = timeRange_start + maxIndex(scorecands)
                starting = false
            }
        }
        
        // Find the best point to end the beat tracking
        var cScoreHasLocalMaxima = localMax(cScore)
        var cScoreLocalMaxima : [Float] = []
        for i in 0 ..< cScore.count - 1 {
            if(cScoreHasLocalMaxima[i] == 1) {
                cScoreLocalMaxima.append(cScore[i])
            }
        }
        let medscore = median(cScoreLocalMaxima)
        var bestEndPoss : [Float] = []
        for i in 0 ..< cScore.count - 1 {
            if ((cScore[i] * Float(cScoreHasLocalMaxima[i])) > 0.5*medscore) {
                bestEndPoss.append(Float(i))
            }
        }
        let bestEndX = Int(max(bestEndPoss))
        
        // This finally extracts the beat times
        var beatTimes : [Int] = [bestEndX]
        while(backLink[beatTimes.last!] > 0) {
            beatTimes.append(backLink[beatTimes.last!])
        }
        beatTimes.reverse()
        
        // Choose start and end looking only on the beats
        var boe : [Float] = []
        for b in beatTimes {
            boe.append(localScore[b])
        }
        let bWindowLength = 5
        var sboe = conv(hanningWindow(bWindowLength), boe)
        sboe = Array(sboe[Int(floor(Double(bWindowLength/2))+1)...boe.count])
        let thsboe = 0.5 * sqrt(mean(pow(sboe,2)))
        var bIndices : [Float] = []
        for i in 0 ..< sboe.count {
            if sboe[i]>thsboe {
                bIndices.append(Float(i))
            }
        }
        beatTimes = Array(beatTimes[Int(min(bIndices)+1)...Int(max(bIndices)+2)])
        
        // Times it by the magic constant oesr that converts back to original sample rate
        var beatsInSeconds : [Float] = []
        for beat in beatTimes {
            beatsInSeconds.append( Float(beat) / oesr )
        }
        
        return beatsInSeconds
    }

}
