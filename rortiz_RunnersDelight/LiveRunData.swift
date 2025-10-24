
// filename: LiveRunData.swift

import Foundation
import CoreLocation

struct RouteSegment: Identifiable {
    let id = UUID()
    var coordinates: [CLLocationCoordinate2D] = []
}

struct LiveRunData {
    var speedMetersPerSecond: CLLocationSpeed = 0.0
    var speedAccuracy: CLLocationDirectionAccuracy = 0
    var altitude: CLLocationDistance = 0
    var course: CLLocationDirection = 0
    var courseAccuracy: CLLocationDirectionAccuracy = 0
    var distanceMovedMeters: CLLocationDistance = 0.0
    var durationInSeconds: Double = 0.0
    var routeSegments: [RouteSegment] = [RouteSegment()]

    var currentPaceInSecondsPerMile: Double {
        guard speedMetersPerSecond > 0.1 else{
            return 0.0
        }
        return 1609.34 / speedMetersPerSecond
    }
    
    var currentPaceInMinutesPerMile: Double {
        guard speedMetersPerSecond > 0.1 else{
            return 0.0
        }
        return currentPaceInSecondsPerMile / 60.00
    }
        
    var distanceMovedMiles: Double {
        return distanceMovedMeters / 1609.34
    }
    
    var averagePaceInMinutesPerMile: Double {
        return (durationInSeconds / 60.00) / distanceMovedMiles
    }
    

}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
