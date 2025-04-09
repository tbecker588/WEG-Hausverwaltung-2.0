import CoreData
import OSLog

class CoreDataStack: ObservableObject {
    // MARK: - Singleton

    static let shared = CoreDataStack()
    private let logger = Logger(subsystem: "WEG-Hausverwaltung", category: "CoreData")

    private init() {}

    // MARK: - Eigenschaften

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WEGHausverwaltung_2_0")

        container.loadPersistentStores { description, error in
            if let error = error {
                self.logger.error("CoreData Fehler: \(error.localizedDescription)")
                fatalError("CoreData Fehler: \(error)")
            }
        }

        return container
    }()

    var context: NSManagedObjectContext {
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
                self.logger.error("Unresolved error \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    // MARK: - Performance Optimierungen
    func optimizeForPerformance() {
        context.performAndWait {
            context.shouldDeleteInaccessibleFaults = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            logger.info("CoreData Performance-Optimierungen aktiviert")
        }
    }

    // MARK: - Backup-Verwaltung
    func createBackup() throws -> URL {
        guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
            logger.error("Datenbank nicht gefunden")
            throw CoreDataError.storeNotFound
        }

        let backupURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("backup_\(Date().ISO8601Format()).sqlite")

        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        logger.info("Backup erstellt: \(backupURL.lastPathComponent)")
        return backupURL
    }

    // MARK: - Migrations-Management
    func handleMigrations() {
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        persistentContainer.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        persistentContainer.persistentStoreDescriptions.first?.setOption(options as NSDictionary, forKey: NSPersistentStoreOptionsKey)

        logger.info("Migration-Optionen konfiguriert")
    }

    // MARK: - Fehlerbehandlung
    func handleError(_ error: Error) {
        logger.error("CoreData Fehler aufgetreten: \(error.localizedDescription)")
        // Hier könnte eine Fehlerbehandlungsstrategie implementiert werden
    }
}

// MARK: - Fehler-Typen
enum CoreDataError: Error {
    case storeNotFound
    case backupFailed
    case migrationFailed

    var localizedDescription: String {
        switch self {
        case .storeNotFound:
            return "Datenbank konnte nicht gefunden werden"
        case .backupFailed:
            return "Backup konnte nicht erstellt werden"
        case .migrationFailed:
            return "Migration ist fehlgeschlagen"
        }
    }
}
