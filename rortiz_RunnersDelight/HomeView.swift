import SwiftUI
import CoreLocation
import MapKit

struct HomeView: View {
    @EnvironmentObject var locationDataManager: LocationDataManager
    @State private var runService: RunService?
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    //@State private var runCoordinates: [CLLocationCoordinate2D] = []
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ZStack {
                
                
                // MARK: - Map View
                Map(position: $cameraPosition) {
                    UserAnnotation {
                        Image(systemName: "figure.run")
                            .font(.largeTitle)
                            .foregroundStyle(Color.brandPrimary)
                            .shadow(radius: 4)
                    }
                    // Draw all route segments - now with stable IDs!
                    if let runService = runService {
                        ForEach(runService.liveRunData.routeSegments) { segment in
                            if segment.coordinates.count >= 2 {
                                MapPolyline(coordinates: segment.coordinates, contourStyle: .geodesic)
                                    .stroke(Color.brandPrimary, lineWidth: 3)
                            }
                        }
                    }
                }

                .mapStyle(.standard)
                .ignoresSafeArea()
            
            
            // MARK: - Main UI Container
            VStack {
                Spacer()

                // This is the single, powerful unwrap you wanted.
                // The entire UI card and all its logic will only exist
                // when runService is not nil.
                if let runService = runService {
                    VStack(spacing: 15) {
                        // --- Live Data Display ---
                        VStack(spacing: 5) {
                            Text("Live Run Data")
                                .font(.headline.bold())
                            Text("Duration: \(Duration.seconds(runService.liveRunData.durationInSeconds).formatted(.time(pattern: .hourMinuteSecond)))")
                            Text("Pace: \(runService.liveRunData.currentPaceInMinutesPerMile, specifier: "%.2f") min/mi")
                            Text("Distance: \(runService.liveRunData.distanceMovedMiles, specifier: "%.2f") miles")
                        }
                        .font(.subheadline)
                        
                        // --- Action Buttons ---
                        HStack {
                            // Since we are inside the 'if let', we know runService is not nil.
                            // This simplifies the Stop button.
                            Button("Stop") {
                                stopRun()
                            }
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            
                            // The Pause button also knows runService is not nil.
                            Button(runService.isPaused ? "Resume" : "Pause") {
                                runService.togglePause()
                            }
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }

                    .foregroundStyle(Color.charcoal)
                    .padding(20)
                    .background(Color.lightGrey)
                    .cornerRadius(20)
                    .shadow(color: .charcoal.opacity(0.3), radius: 10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                } else {
                    // MARK: --- UI when NO run is active ---
                    // This is the "Start Run" button, which has its own simple card.
                    VStack(spacing: 15) {
                        Text("Ready to run!")
                            .font(.headline.bold())
                        
                        Button("Start Run") {
                            startRun()
                        }
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .foregroundStyle(Color.charcoal)
                    .padding(20)
                    .background(Color.lightGrey)
                    .cornerRadius(20)
                    .shadow(color: .charcoal.opacity(0.3), radius: 10)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    private func startRun() {
        runService = RunService(locationDataManager: locationDataManager)
        runService?.startTimer()
        
        // Add initial location to the first segment if available
        if let initialLocation = locationDataManager.rawLocation?.coordinate {
            runService?.liveRunData.routeSegments[0].coordinates.append(initialLocation)
        }


        print("🟢 Run started")
    }
    
    private func stopRun() {
        let newRunData = RunLog(distance: runService?.liveRunData.distanceMovedMiles ?? 0.0, duration: runService?.liveRunData.durationInSeconds ?? 0.0, timestamp: Date())
        modelContext.insert(newRunData)
        
        runService?.stopTimer()
        runService?.deinitalizeRunService()
        runService = nil
        print("🔴 Run stopped")
    }

}


