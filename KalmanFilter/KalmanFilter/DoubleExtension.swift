//
//  DoubleExtension.swift
//  KalmanFilterTest
//
//  Created by Oleksii on 20/06/16.
//  Copyright © 2016 Oleksii Dykan. All rights reserved.
//

import Foundation

// MARK: Float as Kalman input
extension Float: KalmanInput {
    public var transposed: Float {
        return self
    }
    
    public var inversed: Float {
        return 1 / self
    }
    
    public var additionToUnit: Float {
        return 1 - self
    }
}

// MARK: Double as Kalman input
extension Double: KalmanInput {
    public var transposed: Double {
        return self
    }
    
    public var inversed: Double {
        return 1 / self
    }
    
    public var additionToUnit: Double {
        return 1 - self
    }
}
