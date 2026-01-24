//
//  RunRoutePoint.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 1/23/26.
//
import Foundation
import SwiftData

@Model
final class RunRoutePoint: Identifiable {
    @Attribute(.unique) var id: UUID

    /// Global sequence to preserve order
    var pointIndex: Int

    /// Segment index (pause/resume)
    var segmentIndex: Int

    var latitude: Double
    var longitude: Double

    @Relationship(inverse: \RunLog.routePoints)
    var run: RunLog

    init(
        id: UUID = UUID(),
        pointIndex: Int,
        segmentIndex: Int,
        latitude: Double,
        longitude: Double,
        run: RunLog
    ) {
        self.id = id
        self.pointIndex = pointIndex
        self.segmentIndex = segmentIndex
        self.latitude = latitude
        self.longitude = longitude
        self.run = run
    }
}
