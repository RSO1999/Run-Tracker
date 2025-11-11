
// filename: CoreMotionManager.swift

import Foundation
import CoreMotion
import Combine

/// Manages real-time pedometer data from CoreMotion.
/// All property updates occur on the main actor for SwiftUI compatibility.
@MainActor
final class CoreMotionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var stepCount: Int = 0
    @Published private(set) var cadence: Double = 0.0 // Steps per minute
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let pedometer = CMPedometer()
    
    // MARK: - Initialization
    
    init() {
        print("CoreMotionManager initialized")
    }
    

    // MARK: - Public Methods
    
    /// Starts fetching real-time step count and cadence updates.
    /// - Returns: Whether tracking was successfully started
    @discardableResult
    func startUpdates() -> Bool {
        // Clear any previous errors
        errorMessage = nil
        
        // Check device capabilities
        guard CMPedometer.isStepCountingAvailable() else {
            let message = "Step counting is not available on this device"
            print(message)
            errorMessage = message
            return false
        }
        
        guard CMPedometer.isCadenceAvailable() else {
            let message = "Cadence tracking is not available on this device"
            print(message)
            errorMessage = message
            return false
        }
        
        // Prevent multiple concurrent tracking sessions
        guard !isTracking else {
            print("Pedometer updates already running")
            return true
        }
        
        print("Starting pedometer updates")
        isTracking = true
        
        // Start updates from current moment
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            // Explicitly dispatch to MainActor since the handler runs on a background thread
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if let error = error {
                    let message = "Pedometer error: \(error.localizedDescription)"
                    print(message)
                    self.errorMessage = message
                    self.isTracking = false
                    return
                }
                
                guard let data else { return }
                
                // Update step count
                self.stepCount = data.numberOfSteps.intValue
                
                // Update cadence (convert from steps/second to steps/minute)
                if let currentCadence = data.currentCadence?.doubleValue {
                    self.cadence = currentCadence * 60.0
                } else {
                    self.cadence = 0.0
                }
            }
        }
        
        return true
    }
    
    /// Stops the delivery of pedometer updates.
    func stopUpdates() {
        guard isTracking else { return }
        
        pedometer.stopUpdates()
        isTracking = false
        print("Pedometer updates stopped")
    }
    
    /// Resets all tracked values to their initial state.
    func reset() {
        stopUpdates()
        stepCount = 0
        cadence = 0.0
        errorMessage = nil
    }
}
