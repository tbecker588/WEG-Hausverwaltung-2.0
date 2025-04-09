/**
 * @brief   Erweiterungen für Owner Entity
 * @author  [IhrName]
 * @date    2024-04-08
 */

import CoreData
import Foundation
import WEG_Hausverwaltung_2_0

@objc(Owner)
public class Owner: NSManagedObject {
    static var preview: Owner {
        let context = PersistenceController.preview.container.viewContext
        let owner = Owner(context: context)
        owner.firstName = "Max"
        owner.lastName = "Mustermann"
        owner.street = "Musterstraße 123"
        owner.zipCode = 12345
        owner.city = "Musterstadt"
        owner.ownershipShare = 16.67
        return owner
    }
}

// MARK: - Dokumentation
/**
 Owner Extensions
 ===============
 Strukturierte Erweiterungen für Owner-Entity
 
 Version: 2.0
 Stand: 09.04.2025 - 15:45 Uhr
 
 ⚠️ KRITISCHE RICHTLINIEN:
 - Keine Änderungen an Datenfeldern
 - Keine Modifikation von Datentypen
 - Keine Umbenennungen von Properties
 
 ✓ ERLAUBTE ÄNDERUNGEN:
 - Code-Strukturierung (MARK)
 - Dokumentation erweitern
 - Hilfsmethoden hinzufügen
 */

// MARK: - Formatierung & Anzeige
extension Owner {
    /// Formatiert Name des Eigentümers
    var displayName: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    /// Formatiert Adresse des Eigentümers
    var formattedAddress: String {
        [
            street,
            [String(zipCode), city].joined(separator: " ")
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }
}

// MARK: - Berechnungen
extension Owner {
    /// Berechnet den prozentualen Anteil eines Betrags
    /// - Parameter amount: Gesamtbetrag
    /// - Returns: Anteiliger Betrag basierend auf ownershipShare
    func calculateShare(of amount: Double) -> Double {
        guard ownershipShare > 0 else { return 0 }
        return amount * (ownershipShare / 100.0)
    }
}

// MARK: - Validierung
extension Owner {
    /// Prüft Pflichtfelder auf Vollständigkeit
    func validateRequired() -> Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !street.isEmpty &&
        !city.isEmpty &&
        zipCode > 0
    }
    
    /// Prüft die Bankdaten auf Vollständigkeit
    /// - Returns: True wenn IBAN und BIC vorhanden sind
    func validateBankData() -> Bool {
        guard !iban.isEmpty,
              !bic.isEmpty else {
            return false
        }
        return true
    }
    
    /// Schnelle Validierung der wichtigsten Felder
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        ownershipShare > 0
    }
}

// MARK: - Array Extensions
extension Owner {
    /// Sortiert Eigentümer nach Namen (case-insensitive)
    static func sortedByName(_ owners: [Owner]) -> [Owner] {
        owners.sorted { $0.lastName.localizedCaseInsensitiveCompare($1.lastName) == .orderedAscending }
    }

    /// Filtert Eigentümer nach Etage
    static func filterByFloor(_ owners: [Owner], floor: String) -> [Owner] {
        owners.filter { $0.floorNumber?.lowercased() == floor.lowercased() }
    }
}

// MARK: - Array-Zugriffsmethoden

extension Owner {
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
}

// MARK: - Hilfsmethoden

extension Owner {
    func exportiereAlsCSV() -> String {
        [
            displayName,
            formattedAddress,
            String(format: "%.2f", totalLivingSpace),
            String(format: "%.2f", calculateTotalPayments())
        ].joined(separator: ";")
    }
    
    func druckeZusammenfassung() {
        print("""
        👤 \(displayName)
        📫 \(formattedAddress)
        📐 Wohnfläche: \(totalLivingSpace) m²
        💰 Zahlungen: \(calculateTotalPayments()) €
        """)
    }
}

// MARK: - Preview Support
extension Owner {
    /// Erstellt Test-Eigentümer für SwiftUI Previews
    static var preview: Owner {
        let context = PersistenceController.preview.container.viewContext
        let owner = Owner(context: context)
        owner.firstName = "Max"
        owner.lastName = "Mustermann"
        owner.street = "Musterstraße 123"
        owner.zipCode = 12345
        owner.city = "Musterstadt"
        owner.ownershipShare = 16.67
        return owner
    }
}

// MARK: - Beispieldaten für Vorschau

extension Owner {
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
