
// filename: RunService.Swift

import Foundation
import CoreLocation
import SwiftUI
import Combine
import SwiftData


@MainActor
class RunService: ObservableObject {
    
    let instanceID: String
    
    deinit {
        print("[RunService \(instanceID)] ❌ DEINIT")
    }
    
    @Published var liveRunData = LiveRunData()
    
    // Data Collection
    private var samples: [RunSample] = []
    private var lastSampleTime: Date?
    private let sampleInterval: TimeInterval = 1.0

    
    
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

        guard location.timestamp.timeIntervalSinceNow > -5 else {
            print("🗑️ Discarded location: Too old (\(location.timestamp.timeIntervalSinceNow)s).")
            return false
        }

        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 70 else {
            print("🗑️ Discarded location: Inaccurate (\(location.horizontalAccuracy)m).")
            return false
        }
        
        if let previous = previousLocation {
            let distance = location.distance(from: previous)
            let timeInterval = location.timestamp.timeIntervalSince(previous.timestamp)
            
            guard timeInterval > 0 else {
                print("🗑️ Discarded: Zero time interval")
                return false
            }
            
            let calculatedSpeed = distance / timeInterval
            
        
            let maxHumanSpeed: Double = 15.0
            
            guard calculatedSpeed <= maxHumanSpeed else {
                print("🗑️ Discarded: Impossible speed (\(String(format: "%.1f", calculatedSpeed)) m/s, \(String(format: "%.1f", calculatedSpeed * 2.237)) mph)")
                return false
            }
            
            if location.speedAccuracy >= 0 && location.speed >= 0 {
                let appleSpeed = location.speed
                let speedDifference = abs(calculatedSpeed - appleSpeed)
                let averageSpeed = (calculatedSpeed + appleSpeed) / 2.0
                
                if averageSpeed > 0 && speedDifference / averageSpeed > 1.0 {
                    print("🗑️ Discarded: Speed mismatch (calc: \(String(format: "%.1f", calculatedSpeed)) m/s, Apple: \(String(format: "%.1f", appleSpeed)) m/s)")
                    return false
                }
            }
        }
        return true
    }
    
    private func recordSampleIfNeeded() {
        let now = Date()

        if let last = lastSampleTime,
           now.timeIntervalSince(last) < sampleInterval {
            return
        }

        lastSampleTime = now

        let sample = RunSample(
            sampleIndex: samples.count,
            timeOffsetSeconds: liveRunData.durationInSeconds,
            distanceMiles: liveRunData.distanceMovedMiles,
            speedMetersPerSecond: liveRunData.speedMetersPerSecond,
            paceMinPerMile: liveRunData.currentPaceInMinutesPerMile,
            altitudeFeet: (currentLocation?.altitude ?? 0) * 3.28084,
            run: nil
        )

        samples.append(sample)
    }
    func saveRun(context: ModelContext) {
        let run = RunLog(
            startDate: Date().addingTimeInterval(-liveRunData.durationInSeconds),
            endDate: Date(),
            totalDistanceMiles: liveRunData.distanceMovedMiles,
            totalDurationSeconds: liveRunData.durationInSeconds,
            averagePaceMinPerMile: liveRunData.averagePaceInMinutesPerMile,
            elevationGainFeet: 0,   // can compute later
            elevationLossFeet: 0,
            movingTimeSeconds: liveRunData.durationInSeconds,
            pausedTimeSeconds: 0
        )

        // Attach samples
        for sample in samples {
            sample.run = run
        }

        context.insert(run)

        print("✅ Run saved with \(samples.count) samples")
        print("Samples saved: \(samples.count)")
        print("Distance: \(liveRunData.distanceMovedMiles)")
        print("Duration: \(liveRunData.durationInSeconds)")

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
            recordSampleIfNeeded()
            
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
        locationDataManager?.state = .highPower
        locationDataManager?.handleLocationStates()
        
        state = .running(startTime: Date(), accumulatedTime: 0)
        
        startDurationTimer()
        
        print("▶️ RunService: Run started.")
    }
    
    func pause() {
        // This guard ensures we only pause a currently running workout.
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
    
    func end() {

        switch state {
        case .running(let startTime, let accumulatedTime):
            let finalDuration = accumulatedTime + Date().timeIntervalSince(startTime)
            self.liveRunData.durationInSeconds = finalDuration
            print("⏹️ RunService: Final duration calculated from running state: \(finalDuration)")
            
        case .paused(let accumulatedTime):
            self.liveRunData.durationInSeconds = accumulatedTime
            print("⏹️ RunService: Final duration is paused time: \(accumulatedTime)")
            
        case .inactive:
            print("⚠️ RunService: Attempted to end a run that was already inactive.")
            return
        }
        
        
        stopDurationTimer()
        
        state = .inactive
        
        locationDataManager?.state = .lowPower
        locationDataManager?.handleLocationStates()
        
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        currentLocation = nil
        previousLocation = nil
        
        print("⏹️ RunService: Run ended and cleaned up.")
    }
}
