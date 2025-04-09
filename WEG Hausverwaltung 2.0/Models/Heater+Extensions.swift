import CoreData
import Foundation

extension Heater {
    // MARK: - Validierung

    /// Prüft, ob alle erforderlichen Daten vorhanden sind
    var isValid: Bool {
        guard let id,
              let identifier = heaterIdentifier,
              !identifier.isEmpty,
              let room,
              !room.isEmpty,
              factorValue > 0
        else {
            return false
        }
        return true
    }

    // MARK: - Berechnete Eigenschaften

    /// Anzeigename für Listen
    var displayName: String {
        let id = heaterIdentifier ?? identifier ?? "Unbekannt"
        return "\(id) (\(room ?? ""))"
    }

    /// Bereinigter Bezeichner für konsistenten Zugriff
    var cleanIdentifier: String {
        heaterIdentifier ?? identifier ?? "Unbekannt"
    }

    /// Formatierter letzter Zählerstand
    var formattedLastReading: String {
        "Letzter Stand: \(lastReading ?? "0.0")"
    }

    // MARK: - Hilfsmethoden

    /// Fügt eine neue Ablesung hinzu
    /// - Parameters:
    ///   - previousValue: Vorheriger Zählerstand
    ///   - currentValue: Aktueller Zählerstand
    ///   - date: Datum der Ablesung (Standard: jetzt)
    /// - Returns: Die neue Ablesung
    /// - Throws: CoreDataError wenn kein Context verfügbar
    @discardableResult
    func addReading(previousValue: Double, currentValue: Double, date: Date = Date()) throws -> MeterReading {
        guard let context = managedObjectContext else {
            throw CoreDataError.noContext
        }

        let reading = MeterReading(context: context)
        reading.id = UUID()
        reading.date = date
        reading.previousValue = previousValue
        reading.currentValue = currentValue
        reading.heater = self

        lastReading = String(format: "%.1f", currentValue)

        return reading
    }

    /// Ruft die letzte Ablesung ab
    func getLastReading() -> MeterReading? {
        guard let readings = meterReadings as? Set<MeterReading>,
              !readings.isEmpty else { return nil }

        return readings.sorted { $0.date > $1.date }.first
    }

    /// Berechnet den Verbrauch für einen bestimmten Zeitraum
    /// - Parameters:
    ///   - from: Startdatum
    ///   - to: Enddatum
    /// - Returns: Berechneter Verbrauch unter Berücksichtigung des Faktors
    func calculateConsumption(from: Date, to: Date) -> Double {
        guard let readings = meterReadings as? Set<MeterReading>,
              !readings.isEmpty else { return 0.0 }

        let relevantReadings = readings.filter {
            $0.date >= from && $0.date <= to
        }.sorted { $0.date < $1.date }

        guard let firstReading = relevantReadings.first,
              let lastReading = relevantReadings.last else { return 0.0 }

        return (lastReading.currentValue - firstReading.previousValue) * factorValue
    }
}

// MARK: - Fehler-Typen

enum CoreDataError: LocalizedError {
    case noContext

    var errorDescription: String? {
        switch self {
        case .noContext:
            "Kein CoreData Context verfügbar"
        }
    }
}

// MARK: - Preview Support

extension Heater {
    /// Erstellt einen Beispiel-Heizung für SwiftUI Previews
    static func createExample(
        in context: NSManagedObjectContext,
        identifier: String,
        room: String,
        reading: String,
        factor: Double = 1.0
    ) -> Heater {
        let heater = Heater(context: context)
        heater.id = UUID()
        heater.heaterIdentifier = identifier
        heater.room = room
        heater.lastReading = reading
        heater.factorValue = factor
        heater.type = "Radiator"
        heater.installationDate = Date()
        return heater
    }

    static var example: Heater {
        createExample(
            in: PersistenceController.preview.container.viewContext,
            identifier: "HZ-001",
            room: "Wohnzimmer",
            reading: "1234"
        )
    }

    static var examples: [Heater] {
        let context = PersistenceController.preview.container.viewContext
        return [
            createExample(in: context, identifier: "HZ-001", room: "Wohnzimmer", reading: "1234"),
            createExample(in: context, identifier: "HZ-002", room: "Schlafzimmer", reading: "567", factor: 0.8),
        ]
    }
}
