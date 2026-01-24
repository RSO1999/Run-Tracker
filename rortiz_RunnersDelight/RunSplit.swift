//
//  RunSplit.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 1/23/26.

import Foundation
import SwiftData

@Model
final class RunSplit: Identifiable {
    @Attribute(.unique) var id: UUID

    /// 1,2,3… mile number
    var mileIndex: Int

    /// Duration in sec for this mile
    var splitDurationSeconds: Double

    /// avg pace for this split
    var splitPaceMinPerMile: Double

    // Relationship back to parent
    @Relationship(inverse: \RunLog.splits)
    var run: RunLog

    init(
        id: UUID = UUID(),
        mileIndex: Int,
        splitDurationSeconds: Double,
        splitPaceMinPerMile: Double,
        run: RunLog
    ) {
        self.id = id
        self.mileIndex = mileIndex
        self.splitDurationSeconds = splitDurationSeconds
        self.splitPaceMinPerMile = splitPaceMinPerMile
        self.run = run
    }
}
