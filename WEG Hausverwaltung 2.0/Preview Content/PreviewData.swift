import SwiftUI
import CoreData
import Foundation

class PreviewData {
    static let shared = PreviewData()
    
    // CoreData Kontext für Vorschauen
    let context: NSManagedObjectContext
    
    // Beispielobjekte
    let owner: Owner
    let heater: Heater
    let meterReading: MeterReading
    
    private init() {
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // Beispiel-Eigentümer erstellen
        owner = Owner(context: context)
        owner.id = UUID()
        owner.firstName = "Max"
        owner.lastName = "Mustermann"
        owner.apartmentNumber = "A101"
        owner.floorNumber = "1"
        owner.ownershipShare = 16.67
        owner.occupantCount = 2
        
        // Beispiel-Heizung erstellen
        heater = Heater(context: context)
        heater.id = UUID()
        heater.heaterIdentifier = "HZ-001"
        heater.room = "Wohnzimmer"
        heater.lastReading = "1234"
        heater.owner = owner
        
        // Beispiel-Zählerstand erstellen
        meterReading = MeterReading(context: context)
        meterReading.id = UUID()
        meterReading.date = Date()
        meterReading.previousValue = 1000.0
        meterReading.currentValue = 1234.5
        meterReading.heater = heater
    }
}