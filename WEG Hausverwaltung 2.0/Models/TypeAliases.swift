import Foundation
import CoreData
import os.log

// MARK: - Typ-Aliase für CoreData-Entitäten
// ...existing code...

// MARK: - Error Handling
enum AppError: LocalizedError {
    case databaseError(String)
    case validationError(String)
    case networkError(String)
    case fileSystemError(String)
    case securityError(String)
    case unexpectedError(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseError(let message): return "Datenbankfehler: \(message)"
        case .validationError(let message): return "Validierungsfehler: \(message)"
        case .networkError(let message): return "Netzwerkfehler: \(message)"
        case .fileSystemError(let message): return "Dateisystemfehler: \(message)"
        case .securityError(let message): return "Sicherheitsfehler: \(message)"
        case .unexpectedError(let message): return "Unerwarteter Fehler: \(message)"
        }
    }
    
    var logCategory: String {
        switch self {
        case .databaseError: return "DATABASE"
        case .validationError: return "VALIDATION"
        case .networkError: return "NETWORK"
        case .fileSystemError: return "FILESYSTEM"
        case .securityError: return "SECURITY"
        case .unexpectedError: return "UNEXPECTED"
        }
    }
}

// MARK: - Logging
enum LogLevel {
    case debug, info, warning, error
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .error
        case .error: return .fault
        }
    }
}

// MARK: - Logger
struct AppLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WEG", category: "App")
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        logger.log(level: level.osLogType, "\(level.emoji) \(logMessage)")
        #endif
    }
}

// MARK: - Query Protocol
protocol EntityQuery {
    associatedtype Entity: NSManagedObject
    
    /// Findet alle Entitäten
    static func findAll(in context: NSManagedObjectContext) -> [Entity]
    
    /// Findet eine Entität anhand ihrer ID
    static func find(withID id: UUID, in context: NSManagedObjectContext) -> Entity?
    
    /// Findet Entitäten anhand eines Prädikats
    static func find(predicate: NSPredicate, in context: NSManagedObjectContext) -> [Entity]
    
    /// Löscht eine Entität
    static func delete(_ entity: Entity, in context: NSManagedObjectContext) throws
}

// ...existing code...