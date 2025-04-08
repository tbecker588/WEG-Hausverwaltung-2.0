import Foundation
import CoreData

extension Owner {
    /// Markiert, ob der Eigentümer archiviert wurde
    @NSManaged public var isArchived: Bool
    
    /// Optional: Grund für die Archivierung
    @NSManaged public var archiveReason: String?
    
    /// Optional: Datum der Archivierung
    @NSManaged public var archiveDate: Date?
    
    /// Pflichtfeld: Vorname des Eigentümers
    @NSManaged public var firstName: String
    
    /// Pflichtfeld: Nachname des Eigentümers
    @NSManaged public var lastName: String
    
    /// Optional: E-Mail-Adresse
    @NSManaged public var email: String?
    
    /// Optional: Telefonnummer
    @NSManaged public var phone: String?
    
    /// Pflichtfeld: Eigentumsanteil in Prozent
    @NSManaged public var ownershipShare: Double
    
    /// Optional: Anzahl der Bewohner
    @NSManaged public var occupantCount: Int16
    
    /// Beziehung: Zugeordnete Wohnung(en)
    @NSManaged public var apartments: NSSet?
    
    // MARK: - Berechnete Eigenschaften
    
    /// Vollständiger Name des Eigentümers
    public var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    /// Formatierter Eigentumsanteil
    public var formattedShare: String {
        Formatters.percentage(ownershipShare)
    }
    
    /// Archivierungsinformationen
    public var archiveInfo: String? {
        guard isArchived else { return nil }
        let reason = archiveReason ?? "Kein Grund angegeben"
        if let date = archiveDate {
            return "Archiviert am \(Formatters.date(date)): \(reason)"
        }
        return "Archiviert: \(reason)"
    }
}

// MARK: - Generated accessors for apartments
extension Owner {
    @objc(addApartmentsObject:)
    @NSManaged public func addToApartments(_ value: Apartment)
    
    @objc(removeApartmentsObject:)
    @NSManaged public func removeFromApartments(_ value: Apartment)
    
    @objc(addApartments:)
    @NSManaged public func addToApartments(_ values: NSSet)
    
    @objc(removeApartments:)
    @NSManaged public func removeFromApartments(_ values: NSSet)
}