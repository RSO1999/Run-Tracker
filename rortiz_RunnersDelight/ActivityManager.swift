
// ActivityManager.swift

import Foundation
import CoreMotion
import Combine

/// Manages motion activity detection for smart pause during runs.
/// Provides a simple isMoving state that RunService can use to pause/resume tracking.
@MainActor
final class ActivityManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// True when user is actively moving (walking, running, cycling).
    /// False when stationary or in automotive mode.
    @Published private(set) var isMoving: Bool = false
    
    /// The most recent activity (for debugging/logging).
    @Published private(set) var currentActivity: CMMotionActivity?
    
    // MARK: - Private Properties
    
    private let activityManager = CMMotionActivityManager()
    private var isTracking = false
    

    
    // MARK: - Public Methods
    
    /// Check if motion activity tracking is available on this device.
    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }
    
    /// Check current authorization status.
    var authorizationStatus: CMAuthorizationStatus {
        CMMotionActivityManager.authorizationStatus()
    }
    
    /// Starts tracking motion activity for smart pause.
    func startTracking() {
        guard isAvailable else {
            print("⚠️ ActivityManager: Motion activity not available on this device")
            return
        }
        
        let status = authorizationStatus
        guard status != .denied && status != .restricted else {
            print("⚠️ ActivityManager: Motion activity authorization denied/restricted")
            return
        }
        
        guard !isTracking else {
            print("⚠️ ActivityManager: Already tracking")
            return
        }
        
        isTracking = true
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            self?.handleActivityUpdate(activity)
        }
        
        print("🏃‍♂️ ActivityManager: Started tracking")
    }
    
    /// Stops tracking motion activity.
    func stopTracking() {
        guard isTracking else { return }
        
        activityManager.stopActivityUpdates()
        isTracking = false
        isMoving = false
        currentActivity = nil
        
        print("✋ ActivityManager: Stopped tracking")
    }
    
    // MARK: - Private Methods
    
    private func handleActivityUpdate(_ activity: CMMotionActivity?) {
        guard let activity = activity else { return }
        
        currentActivity = activity
        
        // Determine if user is actively moving (for smart pause)
        let wasMoving = isMoving
        
        // User is moving if: walking, running, or cycling
        // User is NOT moving if: stationary or in automotive mode
        isMoving = (activity.walking || activity.running || activity.cycling)
                   && !activity.stationary
                   && !activity.automotive
        
        // Log state changes for debugging
        if wasMoving != isMoving {
            logActivityChange(activity)
        }
    }
    
    private func logActivityChange(_ activity: CMMotionActivity) {
        var states: [String] = []
        if activity.stationary { states.append("stationary") }
        if activity.walking { states.append("walking") }
        if activity.running { states.append("running") }
        if activity.automotive { states.append("automotive") }
        if activity.cycling { states.append("cycling") }
        if activity.unknown { states.append("unknown") }
        
        let confidence = switch activity.confidence {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        @unknown default: "unknown"
        }
        
        print("""
            📍 ActivityManager: State change
               → isMoving: \(isMoving)
               → Activities: \(states.joined(separator: ", "))
               → Confidence: \(confidence)
            """)
    }
}
