import Foundation
import CoreData

class BillingService {
    let context: NSManagedObjectContext
    var billing: Billing
    
    init(context: NSManagedObjectContext, billing: Billing) {
        self.context = context
        self.billing = billing
    }
    
    func finalizeBilling() {
        // Beispielhafte Finalisierung der Abrechnung
        billing.isVerified = true
        billing.verifiedBy = AuthService.shared.currentUser ?? "Unbekannter Benutzer"
        billing.verifiedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Fehler beim Speichern der Abrechnung: \(error)")
        }
        
        // Erzeuge ein PDFService-Objekt und rufe die Instanzmethode lockPDF(for:) auf.
        let pdfService = PDFService()
        pdfService.lockPDF(for: Int(billing.year))
    }
}