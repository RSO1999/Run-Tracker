
// filename: ContentView.swift
// 
import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    @StateObject private var manager = LocationDataManager()
    
    @State private var selection: Int = 0  // Use Int or enum for selection

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "figure.run")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .environmentObject(manager)
    }
}

struct HistoryView: View {
    @Query private var runs: [RunLog]

    var body: some View {
        List {
            ForEach(runs) { run in
                VStack{
                    Text("\(run.distance) miles")
                    let duration = Duration.seconds(run.duration)
                    Text("Time: \(duration.formatted(.time(pattern: .hourMinuteSecond)))")
                    Text("\(run.timestamp, style: .date)")
                }
            }
        }
        

        
    }
}

struct ProfileView: View {
    var body: some View {
        Text("PROFILE")
    }
}
