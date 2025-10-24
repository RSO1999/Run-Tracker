
//filename LocationService.swift

import CoreLocation
import SwiftUI

@MainActor
class LocationDataManager: ObservableObject {
    
    private let locationDataManager = CLLocationManager()
    
    @Published var rawLocation: CLLocation?
    
    init() {
        configureLocationManager()
        startLiveUpdates()
    }

    private func configureLocationManager() {
        if locationDataManager.authorizationStatus == .notDetermined {
            locationDataManager.requestWhenInUseAuthorization()
        }
        locationDataManager.desiredAccuracy = kCLLocationAccuracyBest
        locationDataManager.activityType = .fitness
        locationDataManager.distanceFilter = kCLDistanceFilterNone
    }

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
