import Foundation
import CoreData

@objc(AuditLog)
public class AuditLog: NSManagedObject {
    enum AuditAction: String {
        case create = "CREATE"
        case update = "UPDATE"
        case delete = "DELETE"
    }
}

extension AuditLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuditLog> {
        return NSFetchRequest<AuditLog>(entityName: "AuditLog")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var entityName: String
    @NSManaged public var entityId: String
    @NSManaged public var action: String
    @NSManaged public var changedBy: String
    @NSManaged public var oldValues: Data
    @NSManaged public var newValues: Data
    @NSManaged public var timestamp: Date
    
    // MARK: - Berechnete Eigenschaften
    
    var actionType: AuditAction? {
        get { AuditAction(rawValue: action) }
        set { action = newValue?.rawValue ?? AuditAction.update.rawValue }
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Hilfsmethoden
    
    func storeValues(_ dictionary: [String: Any], isOld: Bool) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        if isOld {
            self.oldValues = data
        } else {
            self.newValues = data
        }
    }
    
    func retrieveValues(isOld: Bool) throws -> [String: Any] {
        let data = isOld ? oldValues : newValues
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "AuditLog", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Ungültiges JSON-Format"
            ])
        }
        return dict
    }
    
    // MARK: - Factory-Methoden
    
    static func createLog(
        context: NSManagedObjectContext,
        entityName: String,
        entityId: String,
        action: AuditAction,
        changedBy: String,
        oldValues: [String: Any],
        newValues: [String: Any]
    ) throws -> AuditLog {
        let log = AuditLog(context: context)
        log.id = UUID()
        log.entityName = entityName
        log.entityId = entityId
        log.action = action.rawValue
        log.changedBy = changedBy
        log.timestamp = Date()
        
        try log.storeValues(oldValues, isOld: true)
        try log.storeValues(newValues, isOld: false)
        
        return log
    }
}

// MARK: - Preview Support
extension AuditLog {
    static var example: AuditLog {
        let context = PersistenceController.preview.container.viewContext
        let log = AuditLog(context: context)
        log.id = UUID()
        log.entityName = "Owner"
        log.entityId = UUID().uuidString
        log.action = AuditAction.update.rawValue
        log.changedBy = "System"
        log.timestamp = Date()
        
        let oldValues = ["name": "Alt"]
        let newValues = ["name": "Neu"]
        
        try? log.storeValues(oldValues, isOld: true)
        try? log.storeValues(newValues, isOld: false)
        
        return log
    }
}