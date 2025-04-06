//
//  WEG_Hausverwaltung_2_0App.swift
//  WEG Hausverwaltung 2.0
//
//  Created by Thomas Becker on 06.04.25.
//

import SwiftUI
import SwiftData

@main
struct WEG_Hausverwaltung_2_0App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
