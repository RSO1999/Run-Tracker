
//filename LocationService.swift

import CoreLocation
import SwiftUI

@MainActor
class LocationDataManager: ObservableObject {
    
    private let locationDataManager = CLLocationManager()
    
    // OBSERVER
    @Published var rawLocation: CLLocation? {
        
        didSet {
            // This will print every time a new location is received from Core Location
            // before it even gets to RunService.
            print("[LocationDataManager] 📍 Published new location: \(rawLocation?.coordinate.latitude ?? 0), \(rawLocation?.coordinate.longitude ?? 0)")
        }
    }
    init() {
        configureLocationManager()
        startLiveUpdates()
    }

    // Configuration Function
    private func configureLocationManager() {
        if locationDataManager.authorizationStatus == .notDetermined {
            locationDataManager.requestWhenInUseAuthorization()
        }
        locationDataManager.desiredAccuracy = kCLLocationAccuracyBest
        locationDataManager.activityType = .fitness
        locationDataManager.distanceFilter = kCLDistanceFilterNone
    }

    // Getting Live Updates
    private func startLiveUpdates() {
        Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    rawLocation = update.location
                }
            } catch {
                print("Location updates failed with error: \(error.localizedDescription)")
            }
        }
    }
}
