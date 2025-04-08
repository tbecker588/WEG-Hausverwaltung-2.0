import CoreData
import Foundation

/// Hilfsfunktionen für das Management der CoreData Store-Pfade
enum StorePathUtility {
    /// Fehler beim Zugriff auf den Store
    enum StoreError: LocalizedError {
        case loadError(String)
        case noStoreFound
        
        var errorDescription: String? {
            switch self {
            case .loadError(let message):
                return "Fehler beim Laden des Stores: \(message)"
            case .noStoreFound:
                return "Kein Store gefunden"
            }
        }
    }
    
    /// Gibt den Pfad zum CoreData Store zurück
    /// - Returns: Store-Pfad oder Fehler
    static func getStorePath() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let container = NSPersistentContainer(name: "WEGHausverwaltung_2_0")
            
            container.loadPersistentStores { description, error in
                if let error = error {
                    continuation.resume(throwing: StoreError.loadError(error.localizedDescription))
                    return
                }
                
                if let path = description.url?.path {
                    continuation.resume(returning: path)
                } else {
                    continuation.resume(throwing: StoreError.noStoreFound)
                }
            }
        }
    }
    
    /// Druckt den Store-Pfad in der Konsole aus
    static func printStorePath() {
        Task {
            do {
                let path = try await getStorePath()
                print("📂 CoreData Store Pfad:")
                print(path)
            } catch {
                print("❌ \(error.localizedDescription)")
            }
        }
    }
    
    /// Überprüft, ob der Store existiert
    /// - Returns: Bool und optional den Pfad
    static func validateStore() async -> (exists: Bool, path: String?) {
        do {
            let path = try await getStorePath()
            return (true, path)
        } catch {
            return (false, nil)
        }
    }
}