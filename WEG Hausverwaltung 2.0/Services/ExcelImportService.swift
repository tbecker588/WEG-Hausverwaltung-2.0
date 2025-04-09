/**
 * WICHTIGER HINWEIS:
 * ==================
 * Dieser Service wird nicht mehr aktiv verwendet (Stand: April 2025).
 * Der Excel-Import wurde aus der Anwendung entfernt.
 *
 * Die Datei wird aus Dokumentationsgründen beibehalten:
 * - Historische Referenz
 * - Nachvollziehbarkeit früherer Datenimporte
 * - Potenzielle Wiederverwendung der Logik
 */

import CoreData
import Foundation

struct HeaterData {
    let identifier: String
    let room: String
    let factor: Double
}

class CSVParser {
    func parseHeaters(from url: URL) -> [HeaterData] {
        var heaters: [HeaterData] = []
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            for line in lines.dropFirst() {
                let components = line.components(separatedBy: ",")
                if components.count >= 3,
                   let factor = Double(components[2].trimmingCharacters(in: .whitespaces))
                {
                    let heaterData = HeaterData(
                        identifier: components[0].trimmingCharacters(in: .whitespaces),
                        room: components[1].trimmingCharacters(in: .whitespaces),
                        factor: factor
                    )
                    heaters.append(heaterData)
                }
            }
        } catch {
            print("Fehler beim Lesen der CSV-Datei: \(error)")
        }
        return heaters
    }
}

class ExcelImportService {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func importFromExcel(url: URL) {
        let parser = CSVParser()
        let heatersData = parser.parseHeaters(from: url)
        saveToCoreData(heaters: heatersData)
    }

    func importHeaters(from _: URL, context: NSManagedObjectContext) {
        let mockExcelData: [[String: String]] = [
            ["Identifier": "HZ001", "Room": "Wohnzimmer", "Factor": "1.0"],
            ["Identifier": "HZ002", "Room": "Schlafzimmer", "Factor": "0.8"],
        ]

        for row in mockExcelData {
            guard let identifier = row["Identifier"],
                  let room = row["Room"]
            else {
                continue
            }

            let heater = Heater(context: context)
            heater.id = UUID()
            heater.heaterIdentifier = identifier
            heater.room = room
            heater.lastReading = "0"
        }

        do {
            try context.save()
        } catch {
            print("Fehler beim Speichern der importierten Heizgeräte: \(error)")
        }
    }

    private func saveToCoreData(heaters: [HeaterData]) {
        for heaterData in heaters {
            let heater = Heater(context: context)
            heater.heaterIdentifier = heaterData.identifier
            // Für factor muss der korrekte Eigenschaftsname verwendet werden
        }

        do {
            try context.save()
            print("Heizkörper erfolgreich importiert!")
        } catch {
            print("Fehler beim Speichern der importierten Heizkörper: \(error)")
        }
    }
}
