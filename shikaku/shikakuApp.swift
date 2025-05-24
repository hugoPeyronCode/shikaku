//
//  shikakuApp.swift
//  shikaku
//
//  Created by Hugo Peyron on 23/05/2025.
//

import SwiftUI
import SwiftData

@main
struct ShikakuApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ShikakuLevel.self,
            GameProgress.self,
            LevelClue.self
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

struct ContentView: View {
    var body: some View {
        ShikakuCalendarView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ShikakuLevel.self, GameProgress.self, LevelClue.self])
}
