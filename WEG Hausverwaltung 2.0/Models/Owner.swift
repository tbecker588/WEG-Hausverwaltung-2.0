/**
 * @class   Owner
 * @brief   Model-Klasse für Eigentümer in der WEG
 *
 * @details Diese Klasse repräsentiert einen Eigentümer in der
 *          Wohnungseigentümergemeinschaft. Sie erweitert das CoreData
 *          NSManagedObject und implementiert zusätzliche Business-Logik.
 *
 * Verwendungszweck:
 * - Verwaltung von Eigentümerdaten
 * - Berechnung von eigentümerspezifischen Werten
 * - Integration mit CoreData
 *
 * @note    Alle Properties sind @NSManaged und werden von CoreData verwaltet
 * @warning Änderungen hier erfordern möglicherweise CoreData Migration
 *
 * @author  [IhrName]
 * @date    2024-04-08
 * @version 1.0
 */

import CoreData
import Foundation

@objc(Owner)
public class Owner: NSManagedObject, Identifiable {
    // MARK: - Managed Properties

    /// Eindeutige ID des Eigentümers (wird automatisch generiert)
    @NSManaged
    private var primitiveId: UUID?

    /// Vorname des Eigentümers (required)
    @NSManaged
    private var primitiveFirstName: String?

    /// Nachname des Eigentümers (required)
    @NSManaged
    private var primitiveLastName: String?

    /// E-Mail Adresse für Korrespondenz (optional)
    @NSManaged
    private var primitiveEmail: String?

    /// Anteil am Gesamteigentum in Prozent (0.0 - 100.0)
    @NSManaged
    private var primitiveOwnershipShare: Double

    /// Anzahl der gemeldeten Bewohner
    @NSManaged
    private var primitiveOccupantCount: Int16

    // Relationships
    @NSManaged
    public var billings: Set<Billing>?
    @NSManaged
    public var heaters: Set<Heater>?

    // MARK: - Public Interface

    /// Öffentlicher Zugriff auf die ID
    public var id: UUID {
        get { primitiveId ?? UUID() }
        set { primitiveId = newValue }
    }

    /// Formatierter Zugriff auf den Vornamen
    public var firstName: String {
        get { primitiveFirstName ?? "" }
        set { primitiveFirstName = newValue.trimmingCharacters(in: .whitespaces) }
    }

    /// Formatierter Zugriff auf den Nachnamen
    public var lastName: String {
        get { primitiveLastName ?? "" }
        set { primitiveLastName = newValue.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Computed Properties

    /// Vollständiger Name des Eigentümers
    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Lifecycle Methods

    /// Wird beim Erstellen eines neuen Eigentümers aufgerufen
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        primitiveId = UUID()
        primitiveOwnershipShare = 0.0
        primitiveOccupantCount = 0
    }

    // MARK: - Validation Methods

    /// Prüft ob alle Pflichtfelder korrekt gesetzt sind
    /// - Returns: True wenn die Daten valide sind
    public func validate() -> Bool {
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              ownershipShare >= 0,
              ownershipShare <= 100
        else {
            return false
        }
        return true
    }
}

// MARK: - Generated accessors for relationships

public extension Owner {
    @objc(addBillingsObject:)
    @NSManaged
    func addToBillings(_ value: Billing)

    @objc(removeBillingsObject:)
    @NSManaged
    func removeFromBillings(_ value: Billing)
}

// MARK: - Documentation Test Cases

#if DEBUG
    /**
     * Beispielverwendung:
     * ```swift
     * let owner = Owner(context: viewContext)
     * owner.firstName = "Max"
     * owner.lastName = "Mustermann"
     * owner.ownershipShare = 50.0
     * try? viewContext.save()
     * ```
     */
    extension Owner {
        static var preview: Owner {
            let context = PersistenceController.preview.container.viewContext
            let owner = Owner(context: context)
            owner.firstName = "Max"
            owner.lastName = "Mustermann"
            owner.email = "max@example.com"
            owner.ownershipShare = 50.0
            owner.occupantCount = 2
            return owner
        }
    }
#endif
