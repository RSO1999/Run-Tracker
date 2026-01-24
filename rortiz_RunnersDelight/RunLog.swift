

// filename: RunLog.swift

//import Foundation
//import SwiftData
//
//@Model
// final class RunLog: Identifiable {
//    var id: UUID
//    var distance: Double
//    var duration: Double 
//    var timestamp: Date
//
//    init(distance: Double, duration: Double, timestamp: Date) {
//        self.id = UUID()
//        self.distance = distance
//        self.duration = duration
//        self.timestamp = timestamp
//    }
//     
//     
//}

import Foundation
import SwiftData

@Model
final class RunLog: Identifiable {
    @Attribute(.unique) var id: UUID
    @Relationship var run: RunLog?


    // Run overview
    var startDate: Date
    var endDate: Date
    var totalDistanceMiles: Double
    var totalDurationSeconds: Double

    /// Precomputed summary (duration ÷ distance)
    var averagePaceMinPerMile: Double

    // Derived elevation numbers (meters to feet conversion as needed)
    var elevationGainFeet: Double
    var elevationLossFeet: Double

    // Time breakdown
    var movingTimeSeconds: Double
    var idleTimeSeconds: Double
    var pausedTimeSeconds: Double

    // Relationships
    @Relationship(deleteRule: .cascade)
    var samples: [RunSample] = []

    @Relationship(deleteRule: .cascade)
    var splits: [RunSplit] = []

    @Relationship(deleteRule: .cascade)
    var routePoints: [RunRoutePoint] = []

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        totalDistanceMiles: Double,
        totalDurationSeconds: Double,
        averagePaceMinPerMile: Double,
        elevationGainFeet: Double = 0,
        elevationLossFeet: Double = 0,
        movingTimeSeconds: Double = 0,
        idleTimeSeconds: Double = 0,
        pausedTimeSeconds: Double = 0
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.totalDistanceMiles = totalDistanceMiles
        self.totalDurationSeconds = totalDurationSeconds
        self.averagePaceMinPerMile = averagePaceMinPerMile
        self.elevationGainFeet = elevationGainFeet
        self.elevationLossFeet = elevationLossFeet
        self.movingTimeSeconds = movingTimeSeconds
        self.idleTimeSeconds = idleTimeSeconds
        self.pausedTimeSeconds = pausedTimeSeconds
    }
}

