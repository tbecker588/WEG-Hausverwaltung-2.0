import XCTest
import CoreData
@testable import WEG_Hausverwaltung_2_0

class CalculationServiceTests: XCTestCase {

    var context: NSManagedObjectContext!
    var calculationService: CalculationService!

    override func setUp() {
        super.setUp()
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (_, error) in
            XCTAssertNil(error, "Fehler beim Laden des In-Memory Stores: \(error?.localizedDescription ?? "")")
        }
        context = container.viewContext
        calculationService = CalculationService(context: context)
    }

    override func tearDown() {
        context = nil
        calculationService = nil
        super.tearDown()
    }
    
    func test30PercentRule() {
        let owner = Owner(context: context)
        owner.areaSqm = 81.74
        let cost = calculationService.calculateHeatingCost(owner: owner, year: 2024)
        XCTAssertEqual(cost, 414.52, accuracy: 0.01, "Die Berechnung der Heizkosten entspricht nicht dem erwarteten Wert.")
    }
}
