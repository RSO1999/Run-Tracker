import Foundation
import SwiftData

@Model
final class RunSample: Identifiable {
    @Attribute(.unique) var id: UUID

    var sampleIndex: Int
    var timeOffsetSeconds: Double
    var distanceMiles: Double
    var speedMetersPerSecond: Double
    var paceMinPerMile: Double
    var altitudeFeet: Double

    // ✅ Optional while collecting; set when saving
    @Relationship(inverse: \RunLog.samples)
    var run: RunLog?

    init(
        id: UUID = UUID(),
        sampleIndex: Int,
        timeOffsetSeconds: Double,
        distanceMiles: Double,
        speedMetersPerSecond: Double,
        paceMinPerMile: Double,
        altitudeFeet: Double,
        run: RunLog? = nil
    ) {
        self.id = id
        self.sampleIndex = sampleIndex
        self.timeOffsetSeconds = timeOffsetSeconds
        self.distanceMiles = distanceMiles
        self.speedMetersPerSecond = speedMetersPerSecond
        self.paceMinPerMile = paceMinPerMile
        self.altitudeFeet = altitudeFeet
        self.run = run
    }
}

