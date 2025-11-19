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

                if let runService = runService {
                    VStack(spacing: 15) {
                        // Primary metrics
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
        let newRunService = RunService(locationDataManager: locationDataManager)
        newRunService.start()
        self.runService = newRunService
        print("🟢 Run started")
    }
    
    private func stopRun() {
        let finalDistance = runService?.liveRunData.distanceMovedMiles ?? 0.0
        let finalDuration = runService?.liveRunData.durationInSeconds ?? 0.0
        
        let newRunData = RunLog(distance: finalDistance, duration: finalDuration, timestamp: Date())
        modelContext.insert(newRunData)
        
        runService?.end()
        self.runService = nil
        print("🔴 Run stopped and saved.")
    }
}
