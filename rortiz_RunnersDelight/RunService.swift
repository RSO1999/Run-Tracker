
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
    
    // These properties are essential for the internal
    // logic of the ViewModel to calculate distances.
    @Published var currentLocation: CLLocation?
    @Published var previousLocation: CLLocation?
    @Published var initialLocation: CLLocation?
        
    private var startTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    private var timerCancellable: AnyCancellable?
    
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
        
        let milesConversion = 2.23694
        
        locationDataManager.$rawLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self = self else { return }
                
                // update the current location
                self.currentLocation = location
                
                // MARK: TRACKING LOGIC
                
                // 1. Check for previous location. This is the first
                //    update. Set the previous location and wait for the next update.
                guard self.previousLocation != nil else {
                    self.previousLocation = location
                    return // Exits early and doesnt track distance yet.
                }
                
                // 2. Executes only if we have both a current and previous location.
                //    Safe to track distance.
                self.trackDistance()
                

                // 3. Update properties on the liveRunData model object
                if location.speed >= 0 {
                    self.liveRunData.speed = location.speed * milesConversion
                } else {
                    self.liveRunData.speed = 0
                }
                self.liveRunData.speedAccuracy = location.speedAccuracy
                self.liveRunData.altitude = location.altitude
                self.liveRunData.course = location.course
                self.liveRunData.courseAccuracy = location.courseAccuracy
            }
            .store(in: &cancellables)
    }
    
    func trackDistance() {
        guard let current = self.currentLocation,
              let previous = self.previousLocation else {
            print("Waiting for Location Data")
            return
        }
        
        let changeInDistance = current.distance(from: previous)
        // Update the distanceMoved property on the model
        self.liveRunData.distanceMoved += changeInDistance
        self.previousLocation = current
        
        // Print with the formatted logger
        logDistance(self.liveRunData.distanceMoved)
    }
    
    

    private func logDistance(_ total: CLLocationDistance) {
        // For streamlined and informative debugging
        // Format: "[RunService A4B1] totalDistance=55.5728"
        print("[RunService \(instanceID)] totalDistance=\(String(format: "%.4f", total))")
    }
    
    
    
    func startTimer() {
        
        startTime = Date()
        
        let publisher = Timer.publish(every: 0.05, tolerance: nil, on: .main, in: .default)
            .autoconnect()
        
        timerCancellable = publisher.sink { [weak self] newTime in
            guard let self = self, let start = self.startTime else { return }

            self.liveRunData.elapsedTime = newTime.timeIntervalSince(start)
        }
        
    }
    func stopTimer(){

        
        timerCancellable?.cancel()
        timerCancellable = nil
        startTime = nil
        print(self.liveRunData.elapsedTime)
        
    }
    func deinitalizeRunService() {

        stopTimer()
        
        // Cancel all Combine subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Reset subscription flag
        isSubscribedToLocation = false
        
        // Clear location references
        currentLocation = nil
        previousLocation = nil
        initialLocation = nil
    }
}
