/**
 * @brief   Erweiterungen für Owner Entity
 * @author  [IhrName]
 * @date    2024-04-08
 */

import CoreData
import Foundation
import WEG_Hausverwaltung_2_0

extension WEG_Hausverwaltung_2_0.Owner {
    // MARK: - Berechnete Eigenschaften

    /// Formatierte Anzeige der Wohnungsinformationen
    var displayAddress: String {
        "Wohnung \(apartmentNumber ?? "-"), Etage \(floorNumber ?? "-")"
    }

    // MARK: - Berechnungsmethoden

    /// Berechnet den Eigentumsanteil an einem Gesamtbetrag
    /// - Parameter totalAmount: Der Gesamtbetrag
    /// - Returns: Den anteiligen Betrag basierend auf ownershipShare
    func calculatePropertyShare(of totalAmount: Double) -> Double {
        guard ownershipShare > 0 else { return 0 }
        return totalAmount * (ownershipShare / 100.0)
    }

    // MARK: - Validierungsmethoden

    /// Prüft ob alle Pflichtfelder ausgefüllt sind
    var isValid: Bool {
        !firstName.isEmpty &&
            !lastName.isEmpty &&
            ownershipShare > 0
    }

    // MARK: - Statische Hilfsmethoden

    /// Sortiert Eigentümer nach Namen (case-insensitive)
    static func sortedByName(_ owners: [Owner]) -> [Owner] {
        owners.sorted { $0.lastName.localizedCaseInsensitiveCompare($1.lastName) == .orderedAscending }
    }

    /// Filtert Eigentümer nach Etage
    static func filterByFloor(_ owners: [Owner], floor: String) -> [Owner] {
        owners.filter { $0.floorNumber?.lowercased() == floor.lowercased() }
    }

    // MARK: - Array-Zugriffsmethoden

    /// Zugriff auf die Heizkörper als Array (sortiert nach Raum)
    var heatersArray: [Heater] {
        (heaters as? Set<Heater>)?
            .sorted { $0.room.localizedCaseInsensitiveCompare($1.room) == .orderedAscending } ?? []
    }

    /// Zugriff auf die Mieter als Array (sortiert nach Nachname)
    var tenantsArray: [Tenant] {
        (tenants as? Set<Tenant>)?
            .sorted { $0.lastName.localizedCaseInsensitiveCompare($1.lastName) == .orderedAscending } ?? []
    }

    /// Zugriff auf die Wohnungsabrechnungen als Array (sortiert nach Jahr absteigend)
    var apartmentBillingsArray: [ApartmentBilling] {
        (apartmentBillings as? Set<ApartmentBilling>)?.sorted { $0.year > $1.year } ?? []
    }

    // MARK: - Beispieldaten für Vorschau

    /// Beispieldaten für UI-Vorschauen
    static var examples: [Owner] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        func createOwner(
            firstName: String,
            lastName: String,
            apt: String,
            floor: String,
            share: Double,
            occupants: Int16,
            area: Double
        ) -> Owner {
            let owner = Owner(context: context)
            owner.id = UUID()
            owner.firstName = firstName
            owner.lastName = lastName
            owner.apartmentNumber = apt
            owner.floorNumber = floor
            owner.ownershipShare = share
            owner.occupantCount = occupants
            owner.areaSqm = area
            return owner
        }

        return [
            createOwner(
                firstName: "Max",
                lastName: "Mustermann",
                apt: "A102",
                floor: "1",
                share: 16.67,
                occupants: 2,
                area: 75.0
            ),
            createOwner(
                firstName: "Anna",
                lastName: "Schmidt",
                apt: "B201",
                floor: "2",
                share: 18.33,
                occupants: 3,
                area: 85.0
            ),
        ]
    }

    /// Einzelner Beispiel-Eigentümer
    static var example: Owner { examples[0] }
}
