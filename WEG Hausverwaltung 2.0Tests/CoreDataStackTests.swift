import XCTest
@testable import WEG_Hausverwaltung_2_0

class CoreDataStackTests: XCTestCase {
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack()
    }
    
    func testOptimizeForPerformance() {
        // Wenn
        coreDataStack.optimizeForPerformance()
        
        // Dann
        XCTAssertTrue(coreDataStack.context.shouldDeleteInaccessibleFaults)
        XCTAssertNotNil(coreDataStack.context.mergePolicy)
    }
    
    func testCreateBackup() throws {
        // Wenn
        let backupURL = try coreDataStack.createBackup()
        
        // Dann
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        
        // Aufräumen
        try FileManager.default.removeItem(at: backupURL)
    }
    
    func testHandleMigrations() {
        // Wenn
        coreDataStack.handleMigrations()
        
        // Dann
        let description = coreDataStack.persistentContainer.persistentStoreDescriptions.first
        XCTAssertNotNil(description?.options[NSPersistentHistoryTrackingKey])
        XCTAssertNotNil(description?.options[NSPersistentStoreOptionsKey])
    }
}