@testable import WEG_Hausverwaltung_2_0
import XCTest

/// Test Suite für die Überprüfung der Typ-Aliase und zugehörigen Funktionalitäten
final class TypeAliasesTests: XCTestCase {
    // MARK: - Fehlertests

    /// Überprüft die korrekte Generierung von Fehlermeldungen
    func testFehlermeldungen() throws {
        // Vorbereitung
        let testNachricht = "Test Fehlermeldung"

        // Test & Überprüfung
        XCTAssertEqual(
            AppError.databaseError(testNachricht).errorDescription,
            "Datenbankfehler: \(testNachricht)",
            "Datenbankfehler sollte korrekt formatiert sein"
        )
        XCTAssertEqual(
            AppError.validationError(testNachricht).errorDescription,
            "Validierungsfehler: \(testNachricht)",
            "Validierungsfehler sollte korrekt formatiert sein"
        )
    }

    /// Überprüft die korrekte Zuweisung von Fehlerkategorien
    func testFehlerkategorien() throws {
        // Vorbereitung
        let fehler = AppError.databaseError("Test")

        // Durchführung
        let kategorie = fehler.logCategory

        // Überprüfung
        XCTAssertEqual(kategorie, "DATABASE", "Fehlerkategorie sollte 'DATABASE' sein")
    }

    // MARK: - Protokollierungsstufen-Tests

    /// Überprüft die korrekten Emoji-Zuweisungen für Protokollierungsstufen
    func testProtokollierungsstufenEmojis() throws {
        // Test & Überprüfung
        XCTAssertEqual(LogLevel.debug.emoji, "🔍", "Debug-Emoji nicht korrekt")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️", "Info-Emoji nicht korrekt")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️", "Warnung-Emoji nicht korrekt")
        XCTAssertEqual(LogLevel.error.emoji, "🚨", "Fehler-Emoji nicht korrekt")
    }

    // MARK: - Protokollierungs-Tests

    /// Überprüft die fehlerfreie Protokollierung von Nachrichten
    func testProtokollierung() throws {
        // Vorbereitung
        let testNachricht = "Test Protokollierung"

        // Test & Überprüfung
        XCTAssertNoThrow(
            AppLogger.log(testNachricht),
            "Protokollierung sollte keine Fehler werfen"
        )
    }

    // MARK: - Entitätsabfrage-Tests

    /// Überprüft die korrekte Funktionsweise des EntityQuery-Protokolls
    func testEntitaetsabfrage() throws {
        // Vorbereitung
        let context = PersistenceController.preview.container.viewContext

        // Durchführung
        let testEntitaet = TestEntity.example(in: context)

        // Überprüfung
        XCTAssertNotNil(testEntitaet, "Testentität sollte erstellt worden sein")
        XCTAssertNoThrow(
            try TestEntity.delete(testEntitaet, in: context),
            "Löschen sollte ohne Fehler möglich sein"
        )
    }
}

// MARK: - Testhilfsmittel

/// Testentität für die Überprüfung des EntityQuery-Protokolls
private class TestEntity: NSManagedObject, EntityQuery {
    /// Erstellt ein Beispiel der Testentität
    static func example(in context: NSManagedObjectContext) -> TestEntity {
        let entitaet = TestEntity(context: context)
        entitaet.setValue(UUID(), forKey: "id")
        return entitaet
    }

    /// Findet alle Testentitäten
    static func findAll(in _: NSManagedObjectContext) -> [TestEntity] {
        []
    }

    /// Findet eine Testentität anhand ihrer ID
    static func find(withID _: UUID, in _: NSManagedObjectContext) -> TestEntity? {
        nil
    }

    /// Findet Testentitäten anhand eines Prädikats
    static func find(predicate _: NSPredicate, in _: NSManagedObjectContext) -> [TestEntity] {
        []
    }

    /// Löscht eine Testentität
    static func delete(_ entity: TestEntity, in context: NSManagedObjectContext) throws {
        context.delete(entity)
    }
}
