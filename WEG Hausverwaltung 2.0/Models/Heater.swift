import Foundation
import CoreData

@objc(Heater)
public class Heater: NSManagedObject { }

extension Heater {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Heater> {
        return NSFetchRequest<Heater>(entityName: "Heater")
    }
    
    @NSManaged public var identifier: String  // z.B. "90878776"
    @NSManaged public var factor: Double       // z.B. Faktor 90
    @NSManaged public var owner: Owner
}