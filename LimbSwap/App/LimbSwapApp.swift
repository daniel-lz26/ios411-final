import SwiftUI
import FirebaseCore

@main
struct LimbSwapApp: App {
    
    init() {
        FirebaseApp.configure()

        // Seed data loads test listings and accounts on first launch.
        // Safe to run multiple times — Firestore setData overwrites duplicates.
        // Comment this out after first successful run if desired.
        Task {
            await SeedData.seedDatabase()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}