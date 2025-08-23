

// filename: LiveRunData.swift
import Foundation
import CoreLocation

/// A model to hold all the live metrics of an active run.
struct LiveRunData {
    var speed: CLLocationSpeed = 0.0
    var speedAccuracy: CLLocationDirectionAccuracy = 0
    var altitude: CLLocationDistance = 0
    var course: CLLocationDirection = 0
    var courseAccuracy: CLLocationDirectionAccuracy = 0
    var distanceMoved: CLLocationDistance = 0.0
    var elapsedTime: Double = 0.0
}
