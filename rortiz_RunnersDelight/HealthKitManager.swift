//
//  HealthKitManager.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 10/23/25.
//

import Foundation
import HealthKit
import CoreLocation

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed
    case workoutSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit is not available on this device"
        case .authorizationFailed: return "Failed to get HealthKit authorization"
        case .workoutSaveFailed(let message): return "Failed to save workout: \(message)"
        }
    }
}

@MainActor
final class HealthKitManager: ObservableObject, @unchecked Sendable {
    
    private let healthStore = HKHealthStore()
    
    private let typesToShare: Set = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute(),
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    init() {}
    
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        // NO WRAPPING NEEDED - has async version!
        try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
    }
    
    
    func saveRunWorkout(
        route: [CLLocation],
        distanceInMiles: Double,
        durationInSeconds: Double,
        startDate: Date
    ) async throws {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor
        
        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: workoutConfiguration,
            device: .local()
        )
        
        let endDate = startDate.addingTimeInterval(durationInSeconds)
        
        do {
            try await builder.beginCollection(at: startDate)
            
            let distanceQuantity = HKQuantity(unit: .mile(), doubleValue: distanceInMiles)
            let distanceSample = HKQuantitySample(
                type: HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                quantity: distanceQuantity,
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([distanceSample])
            
            try await builder.endCollection(at: endDate)
            
            let workout = try await builder.finishWorkout()
            
            guard let finishedWorkout = workout else {
                throw HealthKitError.workoutSaveFailed("Workout was not created")
            }
            
            if !route.isEmpty {
                try await saveRoute(route, to: finishedWorkout)
            }
            
            print("✅ HealthKit workout saved successfully!")
            
        } catch {
            throw HealthKitError.workoutSaveFailed(error.localizedDescription)
        }
    }
    
    private func saveRoute(_ route: [CLLocation], to workout: HKWorkout) async throws {
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        try await routeBuilder.insertRouteData(route)
        try await routeBuilder.finishRoute(with: workout, metadata: nil)
    }
}
