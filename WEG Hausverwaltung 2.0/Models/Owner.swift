import Foundation
import CoreData

@objc(Owner)
public class Owner: NSManagedObject, Identifiable {
    // A. Attribute müssen exakt mit dem Datenmodell übereinstimmen!
    @NSManaged public var name: String
    @NSManaged public var apartment: String
    @NSManaged public var areaSqm: Double
    
    // B. Convenience Accessor
    static func fetchRequest() -> NSFetchRequest<Owner> {
        NSFetchRequest<Owner>(entityName: "Owner")
    }
}