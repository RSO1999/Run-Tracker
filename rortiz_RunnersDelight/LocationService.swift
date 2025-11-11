
// LocationService.swift

import CoreLocation
import SwiftUI

@MainActor
class LocationDataManager: ObservableObject {
    
    private let locationManager = CLLocationManager()
    
    @Published var rawLocation: CLLocation?
    
    init() {
        configureLocationManager()
        startLiveUpdates()
    }

    private func configureLocationManager() {
        // Request authorization if not yet determined
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // TIER 1: Optimal Configuration for Running Apps
        
        // Use highest precision that includes additional sensor fusion
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        // Hint to iOS that this is fitness tracking (optimizes GPS management)
        locationManager.activityType = .fitness
        
        // Get all location updates (we'll filter in code, not hardware)
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Disable automatic pausing - we'll implement smart pause with CoreMotion
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Enable background tracking during active workouts
        
        // Show blue bar for transparency when tracking in background
        locationManager.showsBackgroundLocationIndicator = true
    }

    private func startLiveUpdates() {
        Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    rawLocation = update.location
                }
            } catch {
                // Handle location errors appropriately
                if let clError = error as? CLError {
                    switch clError.code {
                    case .denied:
                        print("Location access denied by user")
                    case .locationUnknown:
                        print("Location temporarily unavailable")
                    default:
                        print("Location error: \(clError.localizedDescription)")
                    }
                } else {
                    print("Location updates failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
}
