import Foundation
import CoreData

// Abrechnungs-Berechnungsservice
class BillingCalculationService {
    // Singleton-Instanz
    static let shared = BillingCalculationService()
    
    // Standardkonstruktor mit CoreData-Kontext
    private init() {
        self.context = CoreDataStack.shared.context
    }
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    
    // MARK: - Init mit externem Kontext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Hauptberechnungsmethoden
    
    /// Berechnet eine neue Jahresabrechnung
    func calculateAnnualBilling(year: Int) throws -> AnnualBilling {
        // Prüfen ob bereits eine Abrechnung für dieses Jahr existiert
        let fetchRequest = NSFetchRequest<AnnualBilling>(entityName: "AnnualBilling")
        fetchRequest.predicate = NSPredicate(format: "year == %d", year)
        
        let existingBillings = try context.fetch(fetchRequest)
        let annualBilling: AnnualBilling
        
        if let existing = existingBillings.first {
            // Bestehende Abrechnung nutzen und Wohnungsabrechnungen löschen
            annualBilling = existing
            
            let apartmentRequest = NSFetchRequest<ApartmentBilling>(entityName: "ApartmentBilling")
            apartmentRequest.predicate = NSPredicate(format: "annualBilling == %@", annualBilling)
            
            let existingApartmentBillings = try context.fetch(apartmentRequest)
            for billing in existingApartmentBillings {
                context.delete(billing)
            }
        } else {
            // Neue Abrechnung erstellen
            annualBilling = AnnualBilling(context: context)
            annualBilling.id = UUID()
            annualBilling.year = Int16(year)
            annualBilling.creationDate = Date()
            
            // Standard-Werte setzen
            annualBilling.totalWaterConsumption = 0
            annualBilling.totalWaterCost = 0
            annualBilling.waterCostPerCubicMeter = 0
            annualBilling.totalGasConsumption = 0
            annualBilling.totalGasCost = 0
            annualBilling.gasCostPerKWh = 0
            annualBilling.totalHeatingConsumption = 0
            annualBilling.warmWaterConsumption = 0
            annualBilling.isFinalized = false
        }
        
        // Warmwasserverbrauch berechnen
        calculateWarmWaterConsumption(for: annualBilling)
        
        // Einzelabrechnungen für jede Wohnung erstellen
        try createApartmentBillings(for: annualBilling)
        
        return annualBilling
    }
    
    /// Berechnet/aktualisiert eine bestehende Jahresabrechnung
    func calculateAnnualBilling(billing: AnnualBilling) throws {
        // Warmwasserverbrauch berechnen
        calculateWarmWaterConsumption(for: billing)
        
        // Einzelabrechnungen erstellen oder aktualisieren
        try createApartmentBillings(for: billing)
        
        // Abrechnung finalisieren
        billing.isFinalized = true
        
        // Änderungen speichern
        try context.save()
    }
    
    /// Finalisiert eine Abrechnung
    func finalizeAnnualBilling(billing: AnnualBilling) throws {
        // Zusätzliche Kosten berechnen
        try calculateAdditionalCosts(for: billing)
        
        // Abrechnung als finalisiert markieren
        billing.isFinalized = true
        
        // Änderungen speichern
        try context.save()
    }
    
    // MARK: - Helper Methods
    
    /// Berechnung des Warmwasserverbrauchs
    private func calculateWarmWaterConsumption(for annualBilling: AnnualBilling) {
        if let heatingConsumption = annualBilling.totalHeatingConsumption as Double?, heatingConsumption > 0 {
            // Standard: 30% des Gasverbrauchs für Warmwasser
            annualBilling.warmWaterConsumption = heatingConsumption * 0.3
        } else {
            annualBilling.warmWaterConsumption = 0
        }
    }
    
    /// Erstellung/Aktualisierung der Wohnungsabrechnungen
    private func createApartmentBillings(for annualBilling: AnnualBilling) throws {
        // Alle Eigentümer abrufen
        let fetchRequest = NSFetchRequest<Owner>(entityName: "Owner")
        let owners = try context.fetch(fetchRequest)
        
        // Bestehende Abrechnungen abrufen, um Duplikate zu vermeiden
        let existingBillingFetch = NSFetchRequest<ApartmentBilling>(entityName: "ApartmentBilling")
        existingBillingFetch.predicate = NSPredicate(format: "annualBilling == %@", annualBilling)
        let existingBillings = try context.fetch(existingBillingFetch)
        
        // Zuordnungstabelle für schnellen Lookup
        var billingsByOwnerId = [UUID?: ApartmentBilling]()
        for billing in existingBillings {
            if let ownerId = billing.owner?.id {
                billingsByOwnerId[ownerId] = billing
            }
        }
        
        // Für jeden Eigentümer eine Abrechnung erstellen oder aktualisieren
        for owner in owners {
            let apartmentBilling: ApartmentBilling
            
            // Bestehende Abrechnung verwenden oder neue erstellen
            if let existingBilling = billingsByOwnerId[owner.id] {
                apartmentBilling = existingBilling
            } else {
                apartmentBilling = ApartmentBilling(context: context)
                apartmentBilling.id = UUID()
                apartmentBilling.year = annualBilling.year
                apartmentBilling.annualBilling = annualBilling
                apartmentBilling.owner = owner
            }
            
            // Berechnung der individuellen Verbräuche und Kosten
            calculateApartmentCosts(for: apartmentBilling, annualBilling: annualBilling)
        }
    }
    
    /// Berechnung der Kosten für eine einzelne Wohnung
    private func calculateApartmentCosts(for apartmentBilling: ApartmentBilling, annualBilling: AnnualBilling) {
        guard let owner = apartmentBilling.owner else { return }
        
        // Eigentumsanteil abrufen
        let ownershipShare = owner.ownershipShare
        
        // Gesamtverbräuche aus der Jahresabrechnung
        let totalWaterConsumption = annualBilling.totalWaterConsumption
        let totalWaterCost = annualBilling.totalWaterCost
        let totalGasConsumption = annualBilling.totalGasConsumption
        let totalGasCost = annualBilling.totalGasCost
        let totalHeatingConsumption = annualBilling.totalHeatingConsumption
        
        // Individuelle Verbräuche berechnen
        let waterConsumption = calculateIndividualConsumption(
            totalConsumption: totalWaterConsumption,
            ownerShare: ownershipShare
        )
        let gasConsumption = calculateIndividualConsumption(
            totalConsumption: totalGasConsumption,
            ownerShare: ownershipShare
        )
        let heatingConsumption = calculateIndividualConsumption(
            totalConsumption: totalHeatingConsumption,
            ownerShare: ownershipShare
        )
        
        // Werte setzen
        apartmentBilling.waterConsumption = waterConsumption
        apartmentBilling.gasConsumption = gasConsumption
        apartmentBilling.heatingConsumption = heatingConsumption
        
        // Kosten berechnen
        // 30% der Kosten werden nach Wohnungsgröße (MEA) verteilt (Grundkosten)
        let baseWaterCost = totalWaterCost * 0.3 * (ownershipShare / 100)
        let baseGasCost = totalGasCost * 0.3 * (ownershipShare / 100)
        let baseHeatingCost = totalGasCost * 0.3 * 0.7 * (ownershipShare / 100) // 70% von Gas für Heizung
        
        apartmentBilling.baseWaterCost = baseWaterCost
        apartmentBilling.baseGasCost = baseGasCost
        apartmentBilling.baseHeatingCost = baseHeatingCost
        
        // 70% der Kosten werden nach Verbrauch verteilt (Verbrauchskosten)
        let consumptionWaterCost = calculateConsumptionCost(
            totalCost: totalWaterCost * 0.7,
            individualConsumption: waterConsumption,
            totalConsumption: totalWaterConsumption
        )
        let consumptionGasCost = calculateConsumptionCost(
            totalCost: totalGasCost * 0.7,
            individualConsumption: gasConsumption,
            totalConsumption: totalGasConsumption
        )
        let consumptionHeatingCost = calculateConsumptionCost(
            totalCost: totalGasCost * 0.7 * 0.7,
            individualConsumption: heatingConsumption,
            totalConsumption: totalHeatingConsumption
        )
        
        apartmentBilling.consumptionWaterCost = consumptionWaterCost
        apartmentBilling.consumptionGasCost = consumptionGasCost
        apartmentBilling.consumptionHeatingCost = consumptionHeatingCost
        
        // Gesamtkosten
        apartmentBilling.waterCost = baseWaterCost + consumptionWaterCost
        apartmentBilling.gasCost = baseGasCost + consumptionGasCost
        apartmentBilling.heatingCost = baseHeatingCost + consumptionHeatingCost
        
        // Gesamtkosten ohne Zusatzkosten
        let baseTotalCosts = apartmentBilling.waterCost + apartmentBilling.gasCost + apartmentBilling.heatingCost
        
        // Wohngeld/Vorauszahlung berechnen, falls noch nicht gesetzt
        if apartmentBilling.totalMonthlyFee == 0 {
            // Geschätzte monatliche Gebühr als Zwölftel der Gesamtkosten
            let estimatedMonthlyFee = baseTotalCosts / 12
            apartmentBilling.totalMonthlyFee = estimatedMonthlyFee
        }
        
        // Gesamtjahresvorauszahlung berechnen
        if apartmentBilling.totalPaidAmount == 0 {
            apartmentBilling.totalPaidAmount = apartmentBilling.totalMonthlyFee * 12
        }
        
        // Gesamtkosten aktualisieren
        updateTotalCosts(for: apartmentBilling)
    }
    
    /// Berechnung des individuellen Verbrauchs
    private func calculateIndividualConsumption(totalConsumption: Double, ownerShare: Double) -> Double {
        return totalConsumption * (ownerShare / 100)
    }
    
    /// Berechnung der verbrauchsabhängigen Kosten
    private func calculateConsumptionCost(
        totalCost: Double,
        individualConsumption: Double,
        totalConsumption: Double
    ) -> Double {
        guard totalConsumption > 0 else { return 0 }
        return totalCost * (individualConsumption / totalConsumption)
    }
    
    /// Berechnung zusätzlicher Kosten
    func calculateAdditionalCosts(for annualBilling: AnnualBilling) throws {
        // Holle alle Wohnungsabrechnungen
        let fetchRequest = NSFetchRequest<ApartmentBilling>(entityName: "ApartmentBilling")
        fetchRequest.predicate = NSPredicate(format: "annualBilling == %@", annualBilling)
        
        let apartmentBillings = try context.fetch(fetchRequest)
        
        // Beispielkosten (in der Praxis sollten diese konfigurierbar sein)
        let wasteCosts = 1200.0  // Müllgebühren
        let commonAreaCosts = 3600.0  // Gemeinschaftskosten
        let otherCosts = 800.0  // Sonstige Kosten
        
        // Verteile die Kosten auf die Wohnungen basierend auf dem Eigentumsanteil
        for apartmentBilling in apartmentBillings {
            guard let owner = apartmentBilling.owner,
                  let ownershipShare = owner.ownershipShare as Double? else {
                continue
            }
            
            // Kosten entsprechend dem Eigentumsanteil zuweisen
            let wasteShare = wasteCosts * (ownershipShare / 100)
            let commonAreaShare = commonAreaCosts * (ownershipShare / 100)
            let otherShare = otherCosts * (ownershipShare / 100)
            
            apartmentBilling.wasteCost = wasteShare
            apartmentBilling.commonAreasCost = commonAreaShare
            apartmentBilling.otherCosts = otherShare
            
            // Gesamtkosten aktualisieren
            updateTotalCosts(for: apartmentBilling)
        }
    }
    
    /// Aktualisiert die Gesamtkosten einer Wohnungsabrechnung
    private func updateTotalCosts(for apartmentBilling: ApartmentBilling) {
        var totalCosts = 0.0
        
        // Grundkosten
        totalCosts += apartmentBilling.waterCost
        totalCosts += apartmentBilling.gasCost
        totalCosts += apartmentBilling.heatingCost
        
        // Zusätzliche Kosten
        if let wasteCost = apartmentBilling.wasteCost {
            totalCosts += wasteCost
        }
        
        if let commonAreasCost = apartmentBilling.commonAreasCost {
            totalCosts += commonAreasCost
        }
        
        if let otherCosts = apartmentBilling.otherCosts {
            totalCosts += otherCosts
        }
        
        // Gesamtkosten speichern
        apartmentBilling.totalCosts = totalCosts
        
        // Saldo aktualisieren
        let finalBalance = apartmentBilling.totalPaidAmount - totalCosts
        apartmentBilling.finalBalance = finalBalance
    }
}
