import Foundation
import CoreData

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
                   let factor = Double(components[2].trimmingCharacters(in: .whitespaces)) {
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
    
    private func saveToCoreData(heaters: [HeaterData]) {
        for heaterData in heaters {
            let heater = Heater(context: context)
            heater.identifier = heaterData.identifier
            heater.factor = heaterData.factor
            // Optional: heater.room = heaterData.room, falls im Model definiert
        }
        
        do {
            try context.save()
            print("Heizkörper erfolgreich importiert!")
        } catch {
            print("Fehler beim Speichern der importierten Heizkörper: \(error)")
        }
    }
}