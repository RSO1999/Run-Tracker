import SwiftUI
import CoreLocation
import MapKit

struct HomeView: View {
    @EnvironmentObject var locationDataManager: LocationDataManager
    
    // Optional RunService - nil when not running, created when user starts
    @State private var runService: RunService?

    @State private var isRunning = false
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    // State to hold the coordinates for drawing the user's path.
    @State private var runCoordinates: [CLLocationCoordinate2D] = []
    
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation {
                    Image(systemName: "figure.run")
                        .font(.largeTitle)
                        // Primary brand color for the runner icon.
                        .foregroundStyle(Color.brandPrimary)
                        .shadow(radius: 4)
                }
                if isRunning && runCoordinates.count >= 2{
                    MapPolyline(coordinates: runCoordinates, contourStyle: .geodesic)
                        .stroke(Color.brandPrimary, lineWidth: 3)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 15) {
                    if let runService = runService {
                        VStack(spacing: 5) {
                            Text("Live Run Data")
                                .font(.headline.bold())
                            Text(String(format: "Speed: %.2f mph", runService.liveRunData.speed))
                            Text(String(format: "Distance: %.2f miles", runService.liveRunData.distanceMoved / 1609.34))
                            Text(String(format: "Time: %.1f seconds", runService.liveRunData.elapsedTime))
                        }
                        .font(.subheadline)
                    } else {
                        Text("Ready to run!")
                            .font(.headline.bold())
                    }
                    
                    Button(isRunning ? "Stop Run" : "Start Run") {
                        isRunning ? stopRun() : startRun()
                    }
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    // theme colors for the button's background.
                    .background(isRunning ? Color.charcoal : Color.brandPrimary)
                    .foregroundColor(.white) // White text for buttons.
                    .cornerRadius(15)
                }
                .onChange(of: locationDataManager.rawLocation) { _, newLocation in
                    if isRunning, let coordinate = newLocation?.coordinate { runCoordinates.append(coordinate) }
                }
                // Apply theme colors to the entire UI card.
                .foregroundStyle(Color.charcoal) // All text inside will be charcoal.
                .padding(20)
                .background(Color.lightGrey) // light grey for the card background.
                .cornerRadius(20)
                .shadow(color: .charcoal.opacity(0.3), radius: 10) // charcoal for shadow.
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func startRun() {
        runService = RunService(locationDataManager: locationDataManager)
        runService?.startTimer()
        
        // Clear previous coordinates and add initial location if available
        runCoordinates.removeAll()
        if let initialLocation = locationDataManager.rawLocation?.coordinate {
            runCoordinates.append(initialLocation)
        }

        isRunning = true
        print("🟢 Run started")
    }
    
    private func stopRun() {
        let newRunData = RunLog(distance: runService?.liveRunData.distanceMoved ?? 0.0, duration: runService?.liveRunData.elapsedTime ?? 0.0, timestamp: Date())
        modelContext.insert(newRunData)
        
        runService?.stopTimer()
        runService?.deinitalizeRunService()
        runService = nil
        isRunning = false
        print("🔴 Run stopped")
    }
}

