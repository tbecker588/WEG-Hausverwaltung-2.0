import Foundation
import CoreData

class CoreDataStack: ObservableObject {
    // MARK: - Singleton
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Eigenschaften
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData Fehler: \(error.localizedDescription)")
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Änderungen speichern
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
