
// filename: RunService.Swift

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class RunService: ObservableObject {
    
    let instanceID: String
    
    deinit {
        print("[RunService \(instanceID)] ❌ DEINIT")
    }

    @Published var liveRunData = LiveRunData()
    

    private var currentLocation: CLLocation?
    private var previousLocation: CLLocation?
    
    private var timerCancellable: AnyCancellable?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var state: WorkoutState = .inactive
    
    weak var locationDataManager: LocationDataManager?
    
    init(locationDataManager: LocationDataManager) {
        self.locationDataManager = locationDataManager
        self.instanceID = String(UUID().uuidString.prefix(4)).uppercased()
        

        print("[RunService \(instanceID)] ✅ INIT")
        subscribeToLocationUpdates(from: locationDataManager)
        

    }
    
    private func subscribeToLocationUpdates(from locationDataManager: LocationDataManager) {

        print("[RunService \(instanceID)] 🚀 Subscribing to location updates.")
        
        locationDataManager.$rawLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                
                print("📍 [RunService \(instanceID)] Received location update. Current state: \(self.state)")
                
                // ADDED FILTER
                guard self.isLocationValid(location) else {
                    return
                }

                
                self.currentLocation = location
                self.liveRunData.speedMetersPerSecond = location.speed
                self.liveRunData.speedAccuracy = location.speedAccuracy
                self.liveRunData.altitude = location.altitude
                self.liveRunData.course = location.course
                self.liveRunData.courseAccuracy = location.courseAccuracy
                
                self.processState(for: location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: FILTERS - Implement Adaptive Filtering Later
    
    private func isLocationValid(_ location: CLLocation) -> Bool {
        // 1. The Timestamp Check: Reject old, cached locations.
        // A location timestamp more than 5 seconds in the past is likely a cached value
        // that the system is providing before it gets a fresh fix.
        guard location.timestamp.timeIntervalSinceNow > -5 else {
            print("🗑️ Discarded location: Too old (\(location.timestamp.timeIntervalSinceNow)s).")
            return false
        }

        // 2. The Accuracy Check: Reject invalid or wildly imprecise locations.
        // A negative accuracy means the location is invalid.
        // We'll use a threshold of 70 meters as our maximum acceptable accuracy for a run.
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 70 else {
            print("🗑️ Discarded location: Inaccurate (\(location.horizontalAccuracy)m).")
            return false
        }
        

        // If both checks pass, the location is considered valid for now.
        return true
    }

    private func processState(for location: CLLocation) {
        switch state {
        case .running:
            guard previousLocation != nil else {
                previousLocation = location
                
                let lastSegmentIndex = max(0, liveRunData.routeSegments.count - 1)
                liveRunData.routeSegments[lastSegmentIndex].coordinates.append(location.coordinate)
                return
            }
            
            let lastSegmentIndex = max(0, liveRunData.routeSegments.count - 1)
            liveRunData.routeSegments[lastSegmentIndex].coordinates.append(location.coordinate)
            
            trackDistance()
            
        case .paused:
            previousLocation = location
            
        case .inactive:
            break
        }
    }
    
    func trackDistance() {
        guard let current = self.currentLocation,
              let previous = self.previousLocation else {
            print("Waiting for Location Data")
            return
        }
        let changeInDistance = current.distance(from: previous)
        self.liveRunData.distanceMovedMeters += changeInDistance
        self.previousLocation = current
        
    }

    private func startDurationTimer() {
        
        // Add this check and print statement
        if timerCancellable != nil {
            print("‼️ [RunService \(instanceID)] TIMER WARNING: A timer already exists. This should not happen.")
        }
        print("⏳ [RunService \(instanceID)] Starting duration timer.")
        
        
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                switch self.state {
                case .running(let startTime, let accumulatedTime):
                    let newDuration = accumulatedTime + Date().timeIntervalSince(startTime)
                    self.liveRunData.durationInSeconds = newDuration
                    
                case .paused(let accumulatedTime):
                    self.liveRunData.durationInSeconds = accumulatedTime
                    
                case .inactive:
                    self.liveRunData.durationInSeconds = 0
                }
            }
    }
    
    private func stopDurationTimer() {
        
        print("⌛️ [RunService \(instanceID)] Stopping duration timer.")

        timerCancellable?.cancel()
        timerCancellable = nil
    }
    

    func start() {
        guard case .inactive = state else {
            print("⚠️ RunService: Attempted to start a run that was not inactive.")
            return
        }
        
        state = .running(startTime: Date(), accumulatedTime: 0)
        
        startDurationTimer()
        print("▶️ RunService: Run started.")
    }

    func pause() {
        guard case .running(let startTime, let accumulatedTime) = state else {
            print("⚠️ RunService: Attempted to pause a run that was not running.")
            return
        }
        let newAccumulatedTime = accumulatedTime + Date().timeIntervalSince(startTime)
        state = .paused(accumulatedTime: newAccumulatedTime)
        
        print("⏸️ RunService: Run paused.")
    }

    func resume() {
        guard case .paused(let accumulatedTime) = state else {
            print("⚠️ RunService: Attempted to resume a run that was not paused.")
            return
        }
        
        state = .running(startTime: Date(), accumulatedTime: accumulatedTime)
        
        liveRunData.routeSegments.append(RouteSegment())
        
        print("▶️ RunService: Run resumed.")
    }
    
    // In RunService.swift, replace the end() method.

    func end() {
        // We switch on the state to handle all cases correctly.
        switch state {
        case .running(let startTime, let accumulatedTime):
            // If the run is stopped while running, we must do one final calculation
            // to capture the duration of the last segment.
            let finalDuration = accumulatedTime + Date().timeIntervalSince(startTime)
            self.liveRunData.durationInSeconds = finalDuration
            print("⏹️ RunService: Final duration calculated from running state: \(finalDuration)")
            
        case .paused(let accumulatedTime):
            // If stopped while paused, the accumulated time is already the final duration.
            self.liveRunData.durationInSeconds = accumulatedTime
            print("⏹️ RunService: Final duration is paused time: \(accumulatedTime)")
            
        case .inactive:
            // If already inactive, do nothing.
            print("⚠️ RunService: Attempted to end a run that was already inactive.")
            return
        }
        
        // --- Perform all cleanup AFTER the final calculation ---
        
        stopDurationTimer()
        state = .inactive
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        currentLocation = nil
        previousLocation = nil
        
        print("⏹️ RunService: Run ended and cleaned up.")
    }
}
