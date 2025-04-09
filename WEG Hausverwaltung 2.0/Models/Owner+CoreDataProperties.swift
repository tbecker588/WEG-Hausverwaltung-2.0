import CoreData
import Foundation

public extension Owner {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Owner> {
        NSFetchRequest<Owner>(entityName: "Owner")
    }

    @NSManaged
    var id: UUID
    @NSManaged
    var isArchived: Bool

    /// Optional: Grund für die Archivierung
    @NSManaged
    var archiveReason: String?

    /// Optional: Datum der Archivierung
    @NSManaged
    var archiveDate: Date?

    /// Pflichtfeld: Vorname des Eigentümers
    @NSManaged
    var firstName: String

    /// Pflichtfeld: Nachname des Eigentümers
    @NSManaged
    var lastName: String

    /// Optional: E-Mail-Adresse
    @NSManaged
    var email: String?

    /// Pflichtfeld: Eigentumsanteil in Prozent
    @NSManaged
    var ownershipShare: Double

    /// Optional: Anzahl der Bewohner
    @NSManaged
    var occupantCount: Int16

    /// Optional: Fläche in Quadratmetern
    @NSManaged
    var areaSqm: Double

    /// Pflichtfeld: Wohnungsnummer
    @NSManaged
    var apartmentNumber: String

    /// Pflichtfeld: Stockwerksnummer
    @NSManaged
    var floorNumber: Int16

    /// Beziehung: Zugeordnete Wohnung(en)
    @NSManaged
    var apartments: NSSet?

    // MARK: - Berechnete Eigenschaften

    /// Vollständiger Name des Eigentümers
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Formatierter Eigentumsanteil
    var formattedShare: String {
        Formatters.percentage(ownershipShare)
    }

    /// Archivierungsinformationen
    var archiveInfo: String? {
        guard isArchived else { return nil }
        let reason = archiveReason ?? "Kein Grund angegeben"
        if let date = archiveDate {
            return "Archiviert am \(Formatters.date(date)): \(reason)"
        }
        return "Archiviert: \(reason)"
    }
}

// MARK: - Generated accessors for apartments

public extension Owner {
    @objc(addApartmentsObject:)
    @NSManaged
    func addToApartments(_ value: Apartment)

    @objc(removeApartmentsObject:)
    @NSManaged
    func removeFromApartments(_ value: Apartment)

    @objc(addApartments:)
    @NSManaged
    func addToApartments(_ values: NSSet)

    @objc(removeApartments:)
    @NSManaged
    func removeFromApartments(_ values: NSSet)
}
