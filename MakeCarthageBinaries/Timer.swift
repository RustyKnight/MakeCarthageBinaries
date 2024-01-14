//
//  Timer.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation

public var durationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.allowedUnits = [ .minute, .second ]
    formatter.zeroFormattingBehavior = [ .pad ]
    return formatter
}()

public class Timer {
    
    internal var startedAt: Date? = nil
    internal var totalRunningTime: TimeInterval = 0 // Used for pause/resume
    
    public var isRunning: Bool = false {
        didSet {
            if isRunning {
                startedAt = Date()
            } else {
                totalRunningTime += currentCycleDuration
                self.startedAt = nil
            }
        }
    }
    
    // This is the amount of time that this cycle has been running,
    // that is, the amount of time since the clock was started to now.
    // It does not include other cycles
    internal var currentCycleDuration: TimeInterval {
        guard let startedAt = startedAt else {
            return 0
        }
        return Date().timeIntervalSince(startedAt)
    }
    
    public func reset() {
        isRunning = false
        totalRunningTime = 0
    }
    
    // This is the "total" amount of time the clock has been allowed
    // to run for, excluding periods when the clock was paused
    public var duration: TimeInterval {
        return totalRunningTime + currentCycleDuration
    }
    
}
