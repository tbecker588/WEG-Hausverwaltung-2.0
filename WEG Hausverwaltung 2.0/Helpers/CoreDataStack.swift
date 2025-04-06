import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }
    
    init(inMemory: Bool = false) {
        // Verwende hier den exakten Namen deiner .xcdatamodeld-Datei. 
        // Falls deine Datei z. B. "WEGHausverwaltung_2_0.xcdatamodeld" heißt, passe den Namen entsprechend an.
        container = NSPersistentContainer(name: "WEGHausverwaltung_2_0")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Fehler beim Laden der Persistent Stores: \(error)")
            }
        }
    }
    
    // Preview-Instanz zur Verwendung in Previews
    static var preview: CoreDataStack = {
        let stack = CoreDataStack(inMemory: true)
        // Hier können ggf. Vorschau-Testdaten eingefügt werden, wenn benötigt.
        return stack
    }()
}