
// filename: ContentView.swift
// 
import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    @StateObject private var manager = LocationDataManager()
    
    @State private var selection: String = "Home"

    
    init() {
        print("[CV] ✅ ContentView INIT")
    }

    var body: some View {
        
        TabView(selection: $selection) {
            Tab("Home",
                systemImage: "figure.run",
                value: "Home")
            {
                HomeView()
            }
            
            Tab("History",
                systemImage: "list.bullet",
                value: "History")
            {
                HistoryView()
            }

            Tab("Profile",
                systemImage: "person.crop.circle.fill",
                value: "Profile")
            {
                ProfileView()
            }
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
