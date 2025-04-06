import Foundation
import CoreData

@objc(AuditLog)
public class AuditLog: NSManagedObject { }

extension AuditLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuditLog> {
        return NSFetchRequest<AuditLog>(entityName: "AuditLog")
    }
    
    @NSManaged public var changedBy: String
    @NSManaged public var oldValues: Data  // JSON-Daten der alten Werte
}