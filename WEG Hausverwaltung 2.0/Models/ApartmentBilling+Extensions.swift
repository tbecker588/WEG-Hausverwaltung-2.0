import Foundation
import CoreData

extension ApartmentBilling {
    // MARK: - Berechnete Eigenschaften
    
    /// Formatierte Jahresangabe
    var yearString: String {
        return String(year)
    }
    
    /// Saldo (Differenz zwischen bezahltem Betrag und Gesamtkosten)
    var balance: Double {
        return totalPaidAmount - totalCosts
    }
    
    /// Formatierter Text für Bilanzsaldo
    var balanceText: String {
        return balance >= 0 ? "Guthaben: \(String(format: "%.2f", balance)) €" : "Nachzahlung: \(String(format: "%.2f", abs(balance))) €"
    }
    
    /// Gibt an, ob der Saldo positiv ist
    var balanceIsPositive: Bool {
        return balance >= 0
    }
    
    /// Status des Saldos (für UI-Zwecke)
    var balanceStatus: String {
        return balance >= 0 ? "Guthaben" : "Nachzahlung"
    }
    
    /// Gesamtbetrag aller Wasserkostenkomponenten
    var totalWaterCost: Double {
        return baseWaterCost + consumptionWaterCost
    }
    
    /// Gesamtbetrag aller Gaskostenkomponenten
    var totalGasCost: Double {
        return baseGasCost + consumptionGasCost
    }
    
    /// Gesamtbetrag aller Heizkostenkomponenten
    var totalHeatingCost: Double {
        return baseHeatingCost + consumptionHeatingCost
    }
    
    /// Gesamtbetrag aller Zusatzkosten
    var totalAdditionalCosts: Double {
        let waste = wasteCost ?? 0.0
        let commonAreas = commonAreasCost ?? 0.0
        let other = otherCosts ?? 0.0
        return waste + commonAreas + other
    }
    
    var displayTitle: String {
        "Abrechnung \(year)"
    }
    
    var totalAmount: Double {
        heatingCosts + waterCosts + additionalCosts
    }
    
    var formattedAmount: String {
        String(format: "%.2f €", totalAmount)
    }
    
    // MARK: - Berechnungsmethoden
    func calculateShare(for owner: Owner) -> Double {
        guard let share = owner.ownershipShare else { return 0 }
        return totalAmount * (share / 100.0)
    }
    
    // MARK: - Beispieldaten für Vorschau
    static var example: ApartmentBilling {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let billing = ApartmentBilling(context: context)
        billing.id = UUID()
        billing.year = Int16(Calendar.current.component(.year, from: Date()) - 1)
        billing.waterConsumption = 80.2
        billing.gasConsumption = 6200.0
        billing.heatingConsumption = 5700.0
        billing.warmWaterConsumption = 500.0
        
        // Kosten
        billing.baseWaterCost = 96.0
        billing.consumptionWaterCost = 224.0
        billing.waterCost = 320.0
        
        billing.baseGasCost = 316.2
        billing.consumptionGasCost = 737.8
        billing.gasCost = 1054.0
        
        billing.baseHeatingCost = 290.7
        billing.consumptionHeatingCost = 678.3
        billing.heatingCost = 969.0
        
        // Zusatzkosten
        billing.wasteCost = 120.0
        billing.commonAreasCost = 180.0
        billing.otherCosts = 90.0
        
        // Summen
        billing.totalMonthlyFee = 200.0
        billing.totalPaidAmount = 2400.0
        billing.totalCosts = 2343.0
        billing.finalBalance = 57.0
        
        return billing
    }
    
    // MARK: - Formatierungshilfsmethoden
    
    /// Formatiert einen Betrag als Währung
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }
    
    /// Formatiert einen Verbrauchswert mit Einheit
    func formatConsumption(_ value: Double, unit: String) -> String {
        return String(format: "%.1f %@", value, unit)
    }
    
    /// Formatiert einen Prozentsatz
    func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
}
