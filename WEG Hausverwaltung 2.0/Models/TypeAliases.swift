import CoreData
import Foundation
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
        case let .databaseError(message): "Datenbankfehler: \(message)"
        case let .validationError(message): "Validierungsfehler: \(message)"
        case let .networkError(message): "Netzwerkfehler: \(message)"
        case let .fileSystemError(message): "Dateisystemfehler: \(message)"
        case let .securityError(message): "Sicherheitsfehler: \(message)"
        case let .unexpectedError(message): "Unerwarteter Fehler: \(message)"
        }
    }

    var logCategory: String {
        switch self {
        case .databaseError: "DATABASE"
        case .validationError: "VALIDATION"
        case .networkError: "NETWORK"
        case .fileSystemError: "FILESYSTEM"
        case .securityError: "SECURITY"
        case .unexpectedError: "UNEXPECTED"
        }
    }
}

// MARK: - Logging

enum LogLevel {
    case debug, info, warning, error

    var emoji: String {
        switch self {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "🚨"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .warning: .error
        case .error: .fault
        }
    }
}

// MARK: - Logger

enum AppLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WEG", category: "App")

    static func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
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
