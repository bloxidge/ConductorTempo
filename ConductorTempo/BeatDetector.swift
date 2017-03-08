//
//  BeatDetector.swift
//  ConductorTempo
//
//  Created by Peter Bloxidge on 07/03/2017.
//  Copyright © 2017 Peter Bloxidge. All rights reserved.
//

import Foundation
import Surge

class BeatDetector {
    
    //! CONSTANTS
    let newSampleRate    : Float = 8000
    let windowWidth      : Int = 256
    let windowHop        : Int = 32
    let numberOfMelBins  : Int = 40
    let nyquistFrequency : Float = 4000
    let tightness        : Float = 400
    let oesr             : Float = 8000/32
    
    struct TempoData {
        var slow  : Float?
        var fast  : Float?
        var ratio : Float?
    }
    
    struct BeatData {
        var positions : [Float]?
        var maximas   : [Int]?
    }
    
    func calculateBeats(data: [Float]) -> [Float] {
        
        print("Spectrum...")
        let bins = melSpectrumBins(data)
        
        print("Calculus...")
        let env = calculateOnsetEnvelope(array: bins)
        
        //! Part 2: Global tempo estimation which calculates the inter-beat interval, τp
        print("Tempo...")
        let tempo = estimateTempo(from: env)
        
        //! Part 3: Beat Tracking and feature extraction
        print("Beats...")
        let beats = beatTracking(tempo, onsetEnvelope: env)
//        let feat = performFeatureExtractionAlgorithm(beat.maximas!, melBins: bins)
        print("Finished!!!")
        
//        return beats
        return beats.positions!
    }
    
    /**
     Perform a fourier transform on the data using a hanning window windowWidth and windowHop advance between frames. This is converted to an 'approximate auditory representation' by mapping the fft spectral bins onto 40 weighted Mel bands. Mel loosely stands for melody and is equal to the range of tones that are expected to be used most often for musical compositions.
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
     */
    func calculateOnsetEnvelope(array: [[Float]] ) -> [Float] {
        
        var decisionWaveform : [Float] = []
        decisionWaveform.reserveCapacity(array.count)
        for i in 0 ..< (array.count - 1) {
            var avg : Float = 0.0
            avg = mean(clip(sub(array[i + 1], y: array[i]), low: 0, high: FLT_MAX))
            decisionWaveform.append(avg)
        }
        
        /* Need to remove DC component and smooth result */
        // a(1)y(n)=b(1)x(n)+b(2)x(n−1)−a(2)y(n−1)
        // filter([1 -1], [1 -.99],mm);
        let x = decisionWaveform
        for j in 1 ..< decisionWaveform.count {
            decisionWaveform[j] = x[j] + (-1*x[j-1]) + (0.99*decisionWaveform[j-1])
        }
        
        return decisionWaveform
    }
    
    /* Global tempo estimation */
    func estimateTempo(from array: [Float]) -> TempoData {
        
        let maxd : Float = 60
        let maxt : Float = 120
        let acmax : Int = Int(round(4*oesr));
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
        rawxcr = mul(rawxcr , y: xcrwin);
        
        // let xpks = localMax(rawxcr)
        // let maximumPeak = max(rawxcr)
        
        var xcr00 = rawxcr; // rawxcr padded with 2 zeros on either end
        xcr00.append(0)
        xcr00.insert(0, at: 0)
        
        // Equation 7: [2] pg.10
        // TPS2(τ) = TPS(τ) + 0.5TPS(2τ) + 0.25TPS(2τ − 1) + 0.25TPS(2τ + 1)
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
        // Equation 8: [2] pg.10
        // TPS3(τ) = TPS(τ) + 0.33TPS(3τ) + 0.33TPS(3τ − 1) + 0.33TPS(3τ + 1)
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
        
        var startpd : Int = 0
        var startpd2 : Int = 0
        
        if max(xcr2) > max(xcr3) {
            startpd = maxIndex(xcr2)
            startpd2 = startpd * 2
        }
        else {
            startpd = maxIndex(xcr3)
            startpd2 = startpd * 3
        }
        
        let slowerTempo = 60.0/(Float(startpd)/oesr)
        let fasterTempo = 60.0/(Float(startpd2)/oesr)
        let pratio = rawxcr[startpd]/(rawxcr[startpd]+rawxcr[startpd2])
        
        var tempo = TempoData(slow: slowerTempo,
                              fast: fasterTempo,
                              ratio: pratio)
        
        // Reorders if it comes out the wrong way around 🙃
        if(tempo.fast < tempo.slow) {
            let fast = tempo.fast
            tempo.fast = tempo.slow
            tempo.slow = fast
        }
        
        return tempo
    }
    
    func beatTracking(_ tempo: TempoData, onsetEnvelope: [Float]) -> BeatData {
        
        /* 🐲🐉 There be dragons here 🐍🐲*/
        var startBPM : Float = 0
        if (tempo.ratio! > 0.5) {
            startBPM = Float(tempo.slow!) // Fast result from the autocorrelation
        }
        else {
            startBPM = Float(tempo.fast!) // Slow result from the autocorrelation
        }
        let pd = (60*oesr)/startBPM // numbeats in onsetEnvelope step, probability there is a beat in each sampling interval
        let onsetEnv = onsetEnvelope // std(onsetEnvelope) // vector which maps change in frequency
        
        /* NOTE: Gaussian probability weighting function centered around 120bpm.
         This is the probability of the tempo of the song taken from experimental evidence */
        var gaussTempoProb : [Float] = []
        for i in Int(-pd) ..< Int(pd) {
            gaussTempoProb.append(-0.5 * pow((Float(i) / (pd/32)), 2))
        }
        gaussTempoProb = exp(gaussTempoProb)
        
        // LocalScore is a smoothed version of the onsetEnv based on the 120bpm window
        var localScore = conv(gaussTempoProb, onsetEnv);
        let sValue = Int(round(Double(gaussTempoProb.count/2)))
        let eValue = Int(onsetEnv.count)
        localScore = Array(localScore[sValue..<eValue])
        
        // Setting up some array variables for the next part
        var backLink : [Int] = Array(repeating: 0, count: localScore.count)
        var cumScore : [Float] = Array(repeating: 0.0, count: localScore.count)
        var prange : [Int] = []; prange.reserveCapacity(512)
        var txwt   : [Float] = []; txwt.reserveCapacity(512)
        
        // Filling the arrays
        for i in Int(round(-2*pd)) ..< Int(-round(pd/2)) {
            prange.append(Int(i))
            txwt.append(abs(pow(log(Float(i) / -pd), 2)) * -tightness)
        }
        
        var starting = true
        /* This creates a recursive estimation of each beat interval */
        for i in 0 ..< localScore.count {
            let timeRange_start = Int(round(-2*pd)) + i
            let zpad : Int = max(0, min(-timeRange_start, prange.count))
            var scorecands = txwt
            var index = 0
            for j in zpad ..< prange.count {
                scorecands[index] = scorecands[index] + cumScore[timeRange_start + j]
                index += 1
            }
            cumScore[i] = max(scorecands) + localScore[i]
            if (starting && localScore[i] < (0.01 * max(localScore))) {
                backLink[i] = -1;
            }
            else {
                backLink[i] = timeRange_start + maxIndex(scorecands)
                starting = false
            }
        }
        
        var cumScoreHasLocalMaxima = localMax(cumScore)
        var maximum : Float = 0.0
        var minimum : Float = 0.0
        for i in 0 ..< cumScore.count - 1 {
            if(cumScoreHasLocalMaxima[i]) {
                if(cumScore[i] > maximum) {
                    maximum = cumScore[i]
                }
                if(cumScore[i] < minimum) {
                    minimum = cumScore[i]
                }
            }
        }
        // Find the best point to end the beat tracking
        var median  = minimum + ((maximum - minimum) / 2)
        var bestEndX : Int = 0
        for var i in stride(from: cumScore.count - 2, to: 0, by: -1) {
            if(cumScoreHasLocalMaxima[i] && ( cumScore[i] > 0.5*median )) {
                bestEndX = i
                i = 0;
            }
        }
        
        // This is my part for the feature extraction
        median  = min(localScore) + ((max(localScore) - min(localScore)) / 2)
        var maximas : [Int] = []
        var localScoreHasLocalMaxima = localMax(localScore)
        for i in 1 ..< (localScore.count - 2){
            if(localScoreHasLocalMaxima[i] && ( localScore[i] > 0.25*median )) {
                maximas.append(i)
            }
        }
        
        // This finally extracts the beat times
        var beatTimes : [Int] = [bestEndX]
        while(backLink[beatTimes.last!] > 0) {
            beatTimes.append(backLink[beatTimes.last!])
        }
        
        // Times it by the magic constant oesr that converts back to original sample rate
        var beatsInSeconds : [Float] = []
        for i in ((0 + 1)...beatTimes.count-1).reversed() {
            beatsInSeconds.append( Float(beatTimes[i]) / oesr )
        }
        
        return BeatData(positions: beatsInSeconds, maximas: maximas)
    }

}
