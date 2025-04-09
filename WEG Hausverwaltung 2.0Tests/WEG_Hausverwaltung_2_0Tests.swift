import CoreData
import Testing
@testable import WEG_Hausverwaltung_2_0

/// Test Suite für die WEG Hausverwaltung App
struct WEG_Hausverwaltung_2_0Tests {
    // MARK: - Test Setup

    /// In-Memory CoreData Container für Tests
    private var container: NSPersistentContainer {
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }

    // MARK: - WEG Tests

    @Test("WEG Erstellung und Validierung")
    func testWEGCreationAndValidation() async throws {
        let context = container.viewContext
        let weg = WEG(context: context)

        weg.name = "Test WEG"
        weg.street = "Teststraße"
        weg.houseNumber = "1"
        weg.city = "Teststadt"
        weg.postalCode = "12345"

        #expect(weg.isValid)
        #expect(weg.fullAddress == "Teststraße 1, 12345 Teststadt")
    }

    @Test("WEG Ungültige Daten")
    func testInvalidWEG() async throws {
        let context = container.viewContext
        let weg = WEG(context: context)

        #expect(!weg.isValid)
    }

    // MARK: - Eigentümer Tests

    @Test("Eigentümer Erstellung")
    func testOwnerCreation() async throws {
        let context = container.viewContext
        let owner = Owner(context: context)

        owner.firstName = "Max"
        owner.lastName = "Mustermann"
        owner.ownershipShare = 50.0

        #expect(owner.fullName == "Max Mustermann")
        #expect(owner.isValid)
    }

    // MARK: - Berechnungs Tests

    @Test("Eigentumsanteil Berechnung")
    func testOwnershipCalculation() async throws {
        let context = container.viewContext
        let owner = Owner(context: context)
        owner.ownershipShare = 25.0

        let totalAmount = 1000.0
        let expectedShare = 250.0

        #expect(owner.calculatePropertyShare(of: totalAmount) == expectedShare)
    }
}

// MARK: - Test Hilfsfunktionen

extension WEG_Hausverwaltung_2_0Tests {
    /// Erstellt Test-WEG mit Standardwerten
    private func createTestWEG(in context: NSManagedObjectContext) -> WEG {
        let weg = WEG(context: context)
        weg.name = "Test WEG"
        weg.street = "Teststraße"
        weg.houseNumber = "1"
        weg.city = "Teststadt"
        weg.postalCode = "12345"
        return weg
    }
}
