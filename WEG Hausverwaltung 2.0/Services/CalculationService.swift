import Foundation
import SwiftUI
import CoreData

class CalculationService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Hilfsfunktionen für Formatierung
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    // MARK: - Berechnungsmethoden
    
    /// Zählerstand für einen Heizkörper abrufen
    func getReading(for heater: Heater, year: Int) -> (previous: Double, current: Double) {
        // Hier sollte die reale Implementierung die tatsächlichen Zählerstände aus dem Jahr abrufen
        // Dummy-Werte für Testzwecke
        return (previous: 100.0, current: 150.0)
    }
    
    /// Gesamtkosten für ein bestimmtes Jahr ermitteln
    func totalCost(for year: Int) -> Double {
        // Dummy-Wert für Testzwecke
        // In der realen Implementierung würde hier die Summe aller Kosten aus der Jahresabrechnung ermittelt
        return 10000.0
    }
    
    /// Summe aller Heizungspunkte für ein Jahr berechnen
    func totalPoints(year: Int) -> Double {
        let fetchRequest = NSFetchRequest<Heater>(entityName: "Heater")
        
        do {
            let heaters = try context.fetch(fetchRequest)
            var totalPoints = 0.0
            
            for heater in heaters {
                let reading = getReading(for: heater, year: year)
                totalPoints += (reading.current - reading.previous) * heater.factor
            }
            
            return totalPoints
        } catch {
            print("Fehler beim Berechnen der Gesamtpunkte: \(error)")
            return 0.0
        }
    }
    
    /// Heizkosten für einen Eigentümer berechnen
    func calculateHeatingCost(owner: Owner, year: Int) -> Double {
        // Heizgeräte des Eigentümers abrufen
        guard let heaters = owner.heaters as? Set<Heater>, !heaters.isEmpty else {
            // Wenn der Owner keine Heizgeräte hat, fallback auf Flächenberechnung
            return calculateBaseCost(owner: owner, year: year)
        }
        
        var ownerTotalPoints = 0.0
        
        // Punkte für jeden Heizkörper berechnen
        for heater in heaters {
            let reading = getReading(for: heater, year: year)
            ownerTotalPoints += (reading.current - reading.previous) * heater.factor
        }
        
        // Gesamtkosten für dieses Jahr
        let totalCost = self.totalCost(for: year)
        
        // Basiskostenanteil (30% der Kosten werden nach Wohnfläche verteilt)
        let baseCost = totalCost * 0.3 * (owner.areaSqm / 1000)
        
        // Verbrauchskostenanteil (70% der Kosten werden nach Verbrauch verteilt)
        let consumptionCost = totalCost * 0.7 * (ownerTotalPoints / totalPoints(year: year))
        
        return baseCost + consumptionCost
    }
    
    /// Grundkostenanteil berechnen (wenn keine Heizkörper vorhanden sind)
    func calculateBaseCost(owner: Owner, year: Int) -> Double {
        let totalCost = self.totalCost(for: year)
        return totalCost * 0.3 * (owner.areaSqm / 1000)
    }
    
    /// Wasserkosten für einen Eigentümer berechnen
    func calculateWaterCost(owner: Owner, year: Int) -> Double {
        // Hier sollte die tatsächliche Berechnungslogik implementiert werden
        // Für Testzwecke wird ein einfacher Flächenanteil berechnet
        let waterTotalCost = 3000.0  // Beispielwert
        return waterTotalCost * (owner.ownershipShare / 100)
    }
    
    /// Müllkosten für einen Eigentümer berechnen
    func calculateWasteCost(owner: Owner, year: Int) -> Double {
        // Müllkosten werden typischerweise nach Personenanzahl verteilt
        let wasteTotalCost = 1200.0  // Beispielwert
        
        // Gesamtzahl der Personen ermitteln
        let fetchRequest = NSFetchRequest<Owner>(entityName: "Owner")
        
        do {
            let owners = try context.fetch(fetchRequest)
            let totalPersons = owners.reduce(0) { $0 + $1.occupantCount }
            
            if totalPersons > 0 {
                return wasteTotalCost * (Double(owner.occupantCount) / Double(totalPersons))
            } else {
                return 0.0
            }
        } catch {
            print("Fehler beim Berechnen der Müllkosten: \(error)")
            return 0.0
        }
    }
    
    /// Gesamtkosten für einen Eigentümer berechnen
    func calculateTotalCosts(for owner: Owner, in year: Int) -> Double {
        let heatingCost = calculateHeatingCost(owner: owner, year: year)
        let waterCost = calculateWaterCost(owner: owner, year: year)
        let wasteCost = calculateWasteCost(owner: owner, year: year)
        
        // Hier könnten weitere Kostenarten hinzugefügt werden
        
        return heatingCost + waterCost + wasteCost
    }
}

// MARK: - UI-Komponenten für die Abrechnung

struct InfoRow: View {
    var title: String
    var value: String
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(isBold ? .primary : .secondary)
        }
    }
}

struct ConsumptionOverviewCard: View {
    var title: String
    var consumption: Double
    var cost: Double
    var unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", consumption)) \(unit)")
                        .font(.title2)
                    Text("Verbrauch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formatCurrency(cost))
                        .font(.title2)
                    Text("Kosten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    // Helper-Funktion für die Karte
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }
}
