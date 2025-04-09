import XCTest
import CoreData
@testable import WEG_Hausverwaltung_2_0

final class OwnerExtensionsTests: XCTestCase {
    var testOwner: WEG_Hausverwaltung_2_0.Owner!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        context = PersistenceController.preview.container.viewContext
        testOwner = WEG_Hausverwaltung_2_0.Owner(context: context)
        
        // Standarddaten für Tests
        testOwner.firstName = "Max"
        testOwner.lastName = "Mustermann"
        testOwner.street = "Musterstraße 123"
        testOwner.zipCode = 12345
        testOwner.city = "Musterstadt"
        testOwner.ownershipShare = 16.67
    }
    
    // MARK: - Formatierungs-Tests
    
    func testDisplayName() {
        // Standard-Test
        XCTAssertEqual(testOwner.displayName, "Max Mustermann")
        
        // Leere Felder Test
        testOwner.firstName = ""
        XCTAssertEqual(testOwner.displayName, "Mustermann")
        
        testOwner.lastName = ""
        XCTAssertEqual(testOwner.displayName, "")
    }
    
    func testFormattedAddress() {
        // Standard-Test
        XCTAssertEqual(testOwner.formattedAddress, "Musterstraße 123\n12345 Musterstadt")
        
        // Ohne Straße
        testOwner.street = ""
        XCTAssertEqual(testOwner.formattedAddress, "12345 Musterstadt")
        
        // Ohne Stadt
        testOwner.street = "Musterstraße 123"
        testOwner.city = ""
        XCTAssertEqual(testOwner.formattedAddress, "Musterstraße 123\n12345")
    }
    
    // MARK: - Berechnungs-Tests
    
    func testCalculateShare() {
        // Standard-Test
        let amount = 1000.0
        let expectedShare = amount * (16.67 / 100.0)
        XCTAssertEqual(testOwner.calculateShare(of: amount), expectedShare, accuracy: 0.01)
        
        // Grenzfälle
        testOwner.ownershipShare = 0
        XCTAssertEqual(testOwner.calculateShare(of: amount), 0)
        
        testOwner.ownershipShare = 100
        XCTAssertEqual(testOwner.calculateShare(of: amount), amount)
    }
    
    // MARK: - Validierungs-Tests
    
    func testValidateRequired() {
        // Standard-Test - Alle Felder gefüllt
        XCTAssertTrue(testOwner.validateRequired())
        
        // Fehlende Felder Tests
        testOwner.firstName = ""
        XCTAssertFalse(testOwner.validateRequired(), "Leerer Vorname sollte false ergeben")
        
        testOwner.firstName = "Max"
        testOwner.lastName = ""
        XCTAssertFalse(testOwner.validateRequired(), "Leerer Nachname sollte false ergeben")
        
        testOwner.lastName = "Mustermann"
        testOwner.street = ""
        XCTAssertFalse(testOwner.validateRequired(), "Leere Straße sollte false ergeben")
        
        testOwner.street = "Musterstraße 123"
        testOwner.city = ""
        XCTAssertFalse(testOwner.validateRequired(), "Leere Stadt sollte false ergeben")
        
        testOwner.city = "Musterstadt"
        testOwner.zipCode = 0
        XCTAssertFalse(testOwner.validateRequired(), "PLZ 0 sollte false ergeben")
    }
    
    // MARK: - Preview Tests
    
    func testPreviewOwner() {
        let previewOwner = WEG_Hausverwaltung_2_0.Owner.preview
        XCTAssertNotNil(previewOwner)
        XCTAssertEqual(previewOwner.firstName, "Max")
        XCTAssertEqual(previewOwner.lastName, "Mustermann")
        XCTAssertEqual(previewOwner.street, "Musterstraße 123")
        XCTAssertEqual(previewOwner.zipCode, 12345)
        XCTAssertEqual(previewOwner.city, "Musterstadt")
        XCTAssertEqual(previewOwner.ownershipShare, 16.67)
    }
}