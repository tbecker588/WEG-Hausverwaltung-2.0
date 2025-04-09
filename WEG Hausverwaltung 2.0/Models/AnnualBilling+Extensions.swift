import CoreData
import Foundation

extension AnnualBilling {
    // MARK: - Berechnete Eigenschaften

    /// Formatiertes Jahr für die Anzeige
    var yearString: String {
        String(year)
    }

    /// Formatiertes Jahr für die Anzeige
    var formattedYear: String {
        "Jahr \(year)"
    }

    /// Formatiertes Erstellungsdatum
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: creationDate)
    }

    /// Status der Abrechnung
    var statusText: String {
        isFinalized ? "Abgeschlossen" : "In Bearbeitung"
    }

    /// Status-Farbe für UI
    var statusColor: String {
        isFinalized ? "green" : "orange"
    }

    // MARK: - Berechnungsmethoden

    /// Berechnet die gesamten Wasserkosten
    var computedTotalWaterCost: Double {
        apartmentBillingsArray.reduce(0) { $0 + $1.waterCost }
    }

    /// Berechnet die gesamten Gaskosten
    var computedTotalGasCost: Double {
        apartmentBillingsArray.reduce(0) { $0 + $1.gasCost }
    }

    /// Berechnet die gesamten Heizkosten
    var computedTotalHeatingCost: Double {
        apartmentBillingsArray.reduce(0) { $0 + $1.heatingCost }
    }

    /// Berechnet die Gesamtkosten aller Kostenarten
    func getTotalCost() -> Double {
        totalWaterCost + totalGasCost
    }

    /// Zugriff auf Wohnungsabrechnungen als sortiertes Array
    var apartmentBillingsArray: [ApartmentBilling] {
        guard let set = apartmentBillings as? Set<ApartmentBilling> else { return [] }
        return Array(set).sorted {
            // Sortieren nach Eigentümernamen, falls verfügbar
            guard let owner1 = $0.owner, let owner2 = $1.owner else { return false }
            return owner1.lastName < owner2.lastName
        }
    }

    // MARK: - Hilfsmethoden

    /// Fügt eine neue Wohnungsabrechnung hinzu
    func addApartmentBilling(for owner: Owner, in context: NSManagedObjectContext) -> ApartmentBilling {
        let billing = ApartmentBilling(context: context)
        billing.id = UUID()
        billing.year = year
        billing.owner = owner
        billing.annualBilling = self

        // Initialisierung mit Standardwerten
        billing.waterConsumption = 0
        billing.gasConsumption = 0
        billing.heatingConsumption = 0
        billing.totalMonthlyFee = 0
        billing.totalPaidAmount = 0
        billing.totalCosts = 0

        return billing
    }

    /// Überprüft, ob für alle Eigentümer Wohnungsabrechnungen existieren
    func validateBillings(in context: NSManagedObjectContext) -> Bool {
        let ownerFetchRequest = NSFetchRequest<Owner>(entityName: "Owner")

        do {
            let owners = try context.fetch(ownerFetchRequest)
            let billingOwners = apartmentBillingsArray.compactMap(\.owner)

            // Prüfen, ob für jeden Eigentümer eine Abrechnung existiert
            for owner in owners {
                if !billingOwners.contains(where: { $0.id == owner.id }) {
                    return false
                }
            }

            return true
        } catch {
            print("Fehler beim Validieren der Abrechnungen: \(error)")
            return false
        }
    }

    // MARK: - Beispieldaten für Vorschau

    static var example: AnnualBilling {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let billing = AnnualBilling(context: context)
        billing.id = UUID()
        billing.year = Int16(Calendar.current.component(.year, from: Date()) - 1)
        billing.creationDate = Date()
        billing.totalWaterConsumption = 240.5
        billing.totalWaterCost = 960.8
        billing.waterCostPerCubicMeter = 3.99
        billing.totalGasConsumption = 18500.0
        billing.totalGasCost = 3145.0
        billing.gasCostPerKWh = 0.17
        billing.totalHeatingConsumption = 17000.0
        billing.warmWaterConsumption = 1500.0
        billing.isFinalized = false
        return billing
    }

    // MARK: - Formatierungshelfer

    /// Formatiert einen Betrag als Währung
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }

    /// Formatiert einen Verbrauchswert
    func formatConsumption(_ value: Double, unit: String) -> String {
        String(format: "%.1f %@", value, unit)
    }
}
