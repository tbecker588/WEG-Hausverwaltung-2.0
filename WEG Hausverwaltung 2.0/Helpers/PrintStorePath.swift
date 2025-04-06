import CoreData

func printStorePath() {
    let container = NSPersistentContainer(name: "WEGHausverwaltung_2_0")
    container.loadPersistentStores { _, error in
        if let error = error {
            fatalError("Fehler beim Laden des Stores: \(error)")
        } else {
            print(container.persistentStoreDescriptions.first?.url?.path ?? "Kein Store")
        }
    }
}