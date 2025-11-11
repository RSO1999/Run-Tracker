//
//  AppStates.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 11/6/25.
//


import Foundation

/// Represents the distinct states of an active workout, ensuring data integrity for each state.
enum WorkoutState {
    case inactive

    /// The workout is actively tracking.
    /// - `startTime`: The moment the current "running" segment began.
    /// - `accumulatedTime`: The total duration of all previous running segments.
    case running(startTime: Date, accumulatedTime: TimeInterval)
    
    /// The workout is paused by the user.
    /// - `accumulatedTime`: The total duration of the run before it was paused.
    case paused(accumulatedTime: TimeInterval)
}
