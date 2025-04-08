import Foundation
import CoreData

// MARK: - WEG Model
@objc(WEG)
public class WEG: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var street: String
    @NSManaged public var houseNumber: String?
    @NSManaged public var city: String
    @NSManaged public var postalCode: String
    @NSManaged public var totalArea: Double
    @NSManaged public var administrator: String?
    @NSManaged public var contact: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var constructionYear: Int16
    @NSManaged public var apartmentCount: Int16
}

// MARK: - Owner Model
@objc(Owner)
public class Owner: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Owner> {
        return NSFetchRequest<Owner>(entityName: "Owner")
    }
    
    @NSManaged private var primitiveFirstName: String?
    @NSManaged private var primitiveLastName: String?
    @NSManaged private var primitiveEmail: String?
    @NSManaged private var primitiveOwnershipShare: Double
    @NSManaged private var primitiveOccupantCount: Int16
    
    public var firstName: String {
        get { primitiveFirstName ?? "" }
        set { primitiveFirstName = newValue }
    }
    
    // Weitere Properties analog
    // ...
}

// MARK: - Generated accessors for billings
extension Owner {
    @objc(addBillingsObject:)
    @NSManaged public func addToBillings(_ value: Billing)
    
    @objc(removeBillingsObject:)
    @NSManaged public func removeFromBillings(_ value: Billing)
    
    @objc(addBillings:)
    @NSManaged public func addToBillings(_ values: NSSet)
    
    @objc(removeBillings:)
    @NSManaged public func removeFromBillings(_ values: NSSet)
}

// MARK: - Tenant Model
@objc(Tenant)
public class Tenant: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    
    // Beziehungen
    @NSManaged public var owner: Owner?
    
    // Berechnete Eigenschaften
    public var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

// MARK: - Heater Model
@objc(Heater)
public class Heater: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var identifier: String  // Vereinheitlicht
    @NSManaged public var room: String
    @NSManaged public var lastReading: String
    @NSManaged public var type: String?
    @NSManaged public var installationDate: Date?
    @NSManaged public var factorValue: Double
    
    // Beziehungen
    @NSManaged public var owner: Owner?
    @NSManaged public var meterReadings: NSSet?
    
    // Berechnete Eigenschaft für den Faktor, wenn factorValue nicht existiert
    public var factor: Double {
        get {
            return factorValue
        }
        set {
            factorValue = newValue
        }
    }
}

// MARK: - MeterReading Model
@objc(MeterReading)
public class MeterReading: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date
    @NSManaged public var currentValue: Double
    @NSManaged public var previousValue: Double
    @NSManaged public var signature: Data?
    
    // Beziehungen
    @NSManaged public var heater: Heater?
    
    // Berechnete Eigenschaften
    public var consumption: Double {
        return currentValue - previousValue
    }
}

// MARK: - AnnualBilling Model
@objc(AnnualBilling)
public class AnnualBilling: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var year: Int16
    @NSManaged public var creationDate: Date
    @NSManaged public var totalWaterConsumption: Double
    @NSManaged public var totalWaterCost: Double
    @NSManaged public var waterCostPerCubicMeter: Double
    @NSManaged public var totalGasConsumption: Double
    @NSManaged public var totalGasCost: Double
    @NSManaged public var gasCostPerKWh: Double
    @NSManaged public var totalHeatingConsumption: Double
    @NSManaged public var warmWaterConsumption: Double
    @NSManaged public var isFinalized: Bool
    
    // Beziehungen
    @NSManaged public var apartmentBillings: NSSet?
    
    // Hilfsmethode für den Zugriff auf apartmentBillings als Array
    public var apartmentBillingsArray: [ApartmentBilling] {
        let set = apartmentBillings as? Set<ApartmentBilling> ?? []
        return Array(set)
    }
}

// MARK: - ApartmentBilling Model
@objc(ApartmentBilling)
public class ApartmentBilling: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var year: Int16  // Jahr für einfacheres Filtern
    @NSManaged public var waterConsumption: Double
    @NSManaged public var gasConsumption: Double // Fehlender Wert aus Extensions
    @NSManaged public var heatingConsumption: Double
    @NSManaged public var warmWaterConsumption: Double // Fehlender Wert aus Extensions
    @NSManaged public var waterCost: Double
    @NSManaged public var gasCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var heatingCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var baseWaterCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var baseGasCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var baseHeatingCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var consumptionWaterCost: Double // Fehlender Wert aus Extensions
    @NSManaged public var consumptionGasCost: Double
    @NSManaged public var consumptionHeatingCost: Double
    @NSManaged public var totalMonthlyFee: Double
    @NSManaged public var totalCosts: Double
    @NSManaged public var totalPaidAmount: Double
    @NSManaged public var finalBalance: Double
    @NSManaged public var wasteCost: Double?
    @NSManaged public var commonAreasCost: Double?
    @NSManaged public var otherCosts: Double?
    
    // Beziehungen
    @NSManaged public var owner: Owner?
    @NSManaged public var annualBilling: AnnualBilling?
}

// MARK: - DistributionSetting Model
@objc(DistributionSetting)
public class DistributionSetting: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var value: Double
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}

// MARK: - Billing Model (zur Ergänzung)
@objc(Billing)
public class Billing: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var year: Int16
    @NSManaged public var isVerified: Bool
    @NSManaged public var verifiedBy: String?
    @NSManaged public var verifiedAt: Date?
}

// MARK: - Distribution Setting Type
public enum DistributionSettingType: String, CaseIterable {
    case fixedTotal
    case perUnit
    case perPerson
    case areaProportional
    case equalShare
}

// MARK: - Hilfsmethoden für NSSet-Erweiterungen
extension NSSet {
    func toArray<T>(of: T.Type) -> [T] {
        return self.compactMap { $0 as? T }
    }
}

// MARK: - CoreDataModel
public class CoreDataModel {
    static let shared = CoreDataModel()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WEG_Hausverwaltung_2_0")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData Fehler: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}
