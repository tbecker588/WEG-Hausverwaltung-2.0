import SwiftUI
import CoreData

struct PreviewData {
    // Erstelle einen In-Memory Core Data Container für Previews
    static let previewContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Fehler beim Laden des In-Memory Stores: \(error)")
            }
        }
        return container
    }()
    
    static var previewContext: NSManagedObjectContext {
        previewContainer.viewContext
    }
    
    // Beispiel-Dummy für einen Owner
    static var testOwner: Owner {
        let owner = Owner(context: previewContext)
        owner.name = "Max Mustermann"
        owner.apartment = "WH2"
        owner.areaSqm = 72.5
        return owner
    }
    
    // Preview-View für OwnerListView mit Testdaten
    static var previewOwnerListView: some View {
        OwnerListView()
            .environment(\.managedObjectContext, previewContext)
    }
}