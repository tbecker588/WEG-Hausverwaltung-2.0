import SwiftUI

/// Haupteinstiegspunkt der WEG Hausverwaltung App
@main
struct WEG_Hausverwaltung_2_0App: App {
    // MARK: - Properties

    /// Zentrale CoreData Verwaltung
    let persistenceController = PersistenceController.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
