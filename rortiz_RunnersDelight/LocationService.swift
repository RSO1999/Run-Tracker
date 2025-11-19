// LocationService.swift

import CoreLocation
import SwiftUI

enum LocationStates{
    case lowPower
    case highPower
}


@MainActor
class LocationDataManager: ObservableObject {
    
    
    private let locationManager = CLLocationManager()
    
    
    var state: LocationStates = .lowPower
    @Published var rawLocation: CLLocation?
    private var liveUpdateTask: Task<Void, Never>? = nil

    
    init() {
        configureLocationManager()

    }

    private func configureLocationManager() {
        // Request authorization if not yet determined
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    func handleLocationStates() {
        switch state {
        case .highPower:
            print("HIGHPOWER MODE")
            // Use highest precision that includes additional sensor fusion
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            
            // Hint to iOS that this is fitness tracking (optimizes GPS management)
            locationManager.activityType = .fitness
            
            // Get all location updates (we'll filter in code, not hardware)
            locationManager.distanceFilter = kCLDistanceFilterNone
            
            // --- ADDED ---
            // This is critical for a running app. It allows location tracking
            // to continue when the user locks the screen or switches apps.
//            locationManager.allowsBackgroundLocationUpdates = true
            
            // Disable automatic pausing - we'll implement smart pause with CoreMotion
            locationManager.pausesLocationUpdatesAutomatically = false
            
            // Show blue bar for transparency when tracking in background
            locationManager.showsBackgroundLocationIndicator = true
            
            liveUpdateTask = Task {
                await self.startLiveUpdates()
            }
            
        case .lowPower:
            print("LOWPOWER MODE")

            // Set a less precise accuracy.
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            
            // Set a distance filter to save battery.
            locationManager.distanceFilter = 50 // meters
            
            // Set the activity type to something other than fitness.
            locationManager.activityType = .other
            
            // --- ADDED ---
            // Explicitly turn off background updates for low-power mode.
            locationManager.allowsBackgroundLocationUpdates = false
            
            // Do not show the blue "location is in use" bar for this mode.
            locationManager.showsBackgroundLocationIndicator = false
            
            liveUpdateTask?.cancel()
        }
        
    }
    
    
    private func startLiveUpdates() async {
        let updates = CLLocationUpdate.liveUpdates(.fitness)
            do {
                for try await update in updates{
                    try Task.checkCancellation()
                    if !update.stationary{
                        rawLocation = update.location
                        
                    }else{
                        print("User is stationary. Ignoring updates.")
                    }
                    
                }
            }
        catch{
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

