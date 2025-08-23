


//
//  rortiz_RunnersDelightApp.swift
//  rortiz_RunnersDelight
//
//  Created by Ryan Ortiz on 7/29/25.
//

import SwiftUI
import SwiftData

@main
struct rortiz_RunnersDelightApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RunLog.self, 

        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
