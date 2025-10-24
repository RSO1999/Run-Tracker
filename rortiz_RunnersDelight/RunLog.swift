

// filename: RunLog.swift

import Foundation
import SwiftData

/// A SwiftData Model to persist a completed run's summary.
@Model
 final class RunLog: Identifiable {
    var id: UUID
    var distance: Double // Stored in meters
    var duration: Double // Stored in seconds
    var timestamp: Date

    init(distance: Double, duration: Double, timestamp: Date) {
        self.id = UUID()
        self.distance = distance
        self.duration = duration
        self.timestamp = timestamp
    }
     
     
}
