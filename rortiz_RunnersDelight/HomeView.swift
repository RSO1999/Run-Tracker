// filename: HomeView.swift

import SwiftUI
import CoreLocation
import MapKit

struct HomeView: View {
    @EnvironmentObject var locationDataManager: LocationDataManager
    @State private var runService: RunService?
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation {
                    Image(systemName: "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(Color.brandPrimary)
                        .shadow(radius: 4)
                }
                // This first `if let` block for the map remains unchanged.
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
            
            VStack {
                Spacer()

                // This second `if let` block is where we make our changes.
                if let runService = runService {
                    VStack(spacing: 15) {
                        VStack(spacing: 5) {
                            Text("Live Run Data")
                                .font(.headline.bold())
                            Text("Duration: \(Duration.seconds(runService.liveRunData.durationInSeconds).formatted(.time(pattern: .hourMinuteSecond)))")
                            Text("Pace: \(runService.liveRunData.currentPaceInMinutesPerMile, specifier: "%.2f") min/mi")
                            Text("Distance: \(runService.liveRunData.distanceMovedMiles, specifier: "%.2f") miles")
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Button("Stop") {
                                stopRun()
                            }
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            
                            // --- MINIMAL NECESSARY CHANGE ---
                            // Replace the old button with a switch on the service's state.
                            switch runService.state {
                            case .running:
                                Button("Pause") {
                                    runService.pause()
                                }
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                
                            case .paused:
                                Button("Resume") {
                                    runService.resume()
                                }
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                
                            case .inactive:
                                // While the service is technically active, it's in an
                                // inactive state, so we show no button. This case
                                // shouldn't be hit often but is here for safety.
                                EmptyView()
                            }
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
                    // The "Ready to run" view remains completely unchanged.
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
    
    // --- MINIMAL NECESSARY CHANGE ---
    private func startRun() {
        // 1. Create the service.
        let newRunService = RunService(locationDataManager: locationDataManager)
        
        // 2. Tell the service to start.
        newRunService.start()
        
        // 3. Assign it to our state property to show the live UI.
        self.runService = newRunService
        
        print("🟢 Run started")
    }
    
    // --- MINIMAL NECESSARY CHANGE ---
    private func stopRun() {
        // 1. Get the final data from the service.
        let finalDistance = runService?.liveRunData.distanceMovedMiles ?? 0.0
        let finalDuration = runService?.liveRunData.durationInSeconds ?? 0.0
        
        // 2. Create and save the log.
        let newRunData = RunLog(distance: finalDistance, duration: finalDuration, timestamp: Date())
        modelContext.insert(newRunData)
        
        // 3. Tell the service to end and clean up.
        runService?.end()
        
        // 4. Set the service to nil to dismiss the live view.
        self.runService = nil
        print("🔴 Run stopped and saved.")
    }
}
