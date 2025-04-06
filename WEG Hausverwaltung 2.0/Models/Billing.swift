import Foundation
import CoreData

@objc(Billing)
public class Billing: NSManagedObject { }

extension Billing {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Billing> {
        return NSFetchRequest<Billing>(entityName: "Billing")
    }
    
    @NSManaged public var year: Int16
    @NSManaged public var isVerified: Bool
    @NSManaged public var verifiedBy: String?
    @NSManaged public var verifiedAt: Date?
}