import Foundation
import CoreData

class CalculationService {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getReading(for heater: Heater, year: Int) -> (previous: Double, current: Double) {
        // Dummy-Werte – passe diese Logik an
        return (previous: 100.0, current: 150.0)
    }
    
    func totalCost(for year: Int) -> Double {
        // Dummy-Wert
        return 10000.0
    }
    
    func totalPoints(year: Int) -> Double {
        // Dummy-Implementierung
        return 100.0
    }
    
    func calculateHeatingCost(owner: Owner, year: Int) -> Double {
        // Da im Model Owner keine "heaters"-Relation existiert,
        // ersetzen wir sie hier durch ein leeres Array (das Ergebnis wird dementsprechend 0 sein).
        let heaters: [Heater] = []
        var ownerTotalPoints = 0.0
        for heater in heaters {
            let reading = getReading(for: heater, year: year)
            ownerTotalPoints += (reading.current - reading.previous) * heater.factor
        }
        let totalCost = totalCost(for: year)
        let baseCost = totalCost * 0.3 * (owner.areaSqm / 1000)
        let consumptionCost = totalCost * 0.7 * (ownerTotalPoints / totalPoints(year: year))
        return baseCost + consumptionCost
    }
}