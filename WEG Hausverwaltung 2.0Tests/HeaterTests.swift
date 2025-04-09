/**
 * @brief   Tests für das Heater-Modell
 * @author  [IhrName]
 * @date    2024-04-08
 */

@testable import WEG_Hausverwaltung_2_0
import XCTest

class HeaterTests: XCTestCase {
    var heater: Heater!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = PersistenceController(inMemory: true).container.viewContext
        heater = Heater(context: context)
    }

    func testHeaterIdentifier() {
        // Given
        heater.heaterIdentifier = "HK-001"

        // Then
        XCTAssertEqual(heater.heaterIdentifier, "HK-001")
    }
}
