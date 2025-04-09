import CoreData
import Foundation

extension MeterReading {
    // MARK: - Berechnete Eigenschaften

    /// Verbrauch: Differenz zwischen aktuellem und vorherigem Wert
    var consumption: Double {
        currentValue - previousValue
    }

    /// Formatiertes Datum der Ablesung
    var formattedDate: String {
        Formatters.date(date ?? Date())
    }

    /// Anzeige der Werte: "Vorjahr → Aktuell"
    var displayValues: String {
        "\(Formatters.consumption(previousValue, unit: "")) → \(Formatters.consumption(currentValue, unit: ""))"
    }

    /// Prüft die Gültigkeit der Ablesung
    var isValid: Bool {
        guard let date,
              previousValue >= 0,
              currentValue >= previousValue
        else {
            return false
        }
        return true
    }

    // MARK: - Berechnungsmethoden

    /// Berechnet die Kosten basierend auf dem Verbrauch
    /// - Parameter pricePerUnit: Preis pro Einheit
    /// - Returns: Berechnete Kosten
    func calculateCost(pricePerUnit: Double) -> Double {
        consumption * pricePerUnit
    }

    /// Formatierte Kostenanzeige
    /// - Parameter pricePerUnit: Preis pro Einheit
    /// - Returns: Formatierter String (z.B. "123,45 €")
    func formattedCost(pricePerUnit: Double) -> String {
        Formatters.currency(calculateCost(pricePerUnit: pricePerUnit))
    }
}

// MARK: - Preview Support

extension MeterReading {
    /// Erstellt ein Beispiel-Ablese-Objekt für SwiftUI Previews
    static var example: MeterReading {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let reading = MeterReading(context: context)
        reading.id = UUID()
        reading.date = Date()
        reading.previousValue = 10100.0
        reading.currentValue = 15150.0
        return reading
    }

    /// Erstellt mehrere Beispiel-Ablesungen für Listen-Previews
    static var examples: [MeterReading] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return [
            createExample(context: context, prev: 10100.0, curr: 15150.0),
            createExample(context: context, prev: 5000.0, curr: 7500.0),
            createExample(context: context, prev: 3000.0, curr: 4200.0),
        ]
    }

    private static func createExample(
        context: NSManagedObjectContext,
        prev: Double,
        curr: Double
    ) -> MeterReading {
        let reading = MeterReading(context: context)
        reading.id = UUID()
        reading.date = Date()
        reading.previousValue = prev
        reading.currentValue = curr
        return reading
    }
}
