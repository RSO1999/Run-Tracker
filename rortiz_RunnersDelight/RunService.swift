import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class RunService: ObservableObject {
    
    let instanceID: String
    private var isSubscribedToLocation = false
    
    deinit {
        print("[RunService \(instanceID)] ❌ DEINIT")
    }

    // All live run metrics are in the LiveRunData model.
    @Published var liveRunData = LiveRunData()
    

    private var currentLocation: CLLocation?
    private var previousLocation: CLLocation?
    private var currentRouteSegment: Int = 0
    
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0.0 // Holds elapsed time during pauses
    private var timerCancellable: AnyCancellable?
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPaused: Bool = false
    
    weak var locationDataManager: LocationDataManager?
    
    init(locationDataManager: LocationDataManager) {
        self.locationDataManager = locationDataManager
        self.instanceID = String(UUID().uuidString.prefix(4)).uppercased()
        print("[RunService \(instanceID)] ✅ INIT")
        subscribeToLocationUpdates(from: locationDataManager)
    }
    
    private func subscribeToLocationUpdates(from locationDataManager: LocationDataManager) {
        guard !isSubscribedToLocation else {
            print("[RunService \(instanceID)] ⚠️ Attempted to re-subscribe. Ignoring.")
            return
        }
        isSubscribedToLocation = true
        print("[RunService \(instanceID)] 🚀 Subscribing to location updates.")
        
        
        locationDataManager.$rawLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                
                if !isPaused{
                    
                    self.currentLocation = location
                    
                    guard self.previousLocation != nil else {
                        self.previousLocation = location
                        return
                        
                    }

                    // Safely get the last segment index
                    let lastSegmentIndex = max(0, self.liveRunData.routeSegments.count - 1)
                    // Correct - access the coordinates array inside the RouteSegment
                    self.liveRunData.routeSegments[lastSegmentIndex].coordinates.append(location.coordinate)

       
                    self.trackDistance()
                }
                
    
                self.liveRunData.speedMetersPerSecond = location.speed
                self.liveRunData.speedAccuracy = location.speedAccuracy
                self.liveRunData.altitude = location.altitude
                self.liveRunData.course = location.course
                self.liveRunData.courseAccuracy = location.courseAccuracy
            }
            .store(in: &cancellables) // This will now compile
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
    

    
    func startTimer() {
        startTime = Date()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] newTime in
                guard let self = self, let start = self.startTime else { return }
                // Add the new interval to the already accumulated time
                self.liveRunData.durationInSeconds = self.accumulatedTime + newTime.timeIntervalSince(start)
            }
    }

    func stopTimer() {
        // Calculate the time passed since the timer started and add it to our total
        if let start = startTime {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        // Cancel the timer and reset the start time
        timerCancellable?.cancel()
        timerCancellable = nil
        startTime = nil
        print("Timer stopped. Accumulated time is \(accumulatedTime)")
    }
    
    func deinitalizeRunService() {
        stopTimer()
        cancellables.forEach { $0.cancel() } // This will now compile
        cancellables.removeAll() // This will now compile
        isSubscribedToLocation = false
        currentLocation = nil
        previousLocation = nil
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            // Actions to perform when pausing
            self.previousLocation = nil
            stopTimer()
            print("⏸️ Run paused")
        } else {
            // Actions to perform when resuming
            startTimer()
            liveRunData.routeSegments.append(RouteSegment())
            print("▶️ Run resumed")
        }
    }

    


   
}
