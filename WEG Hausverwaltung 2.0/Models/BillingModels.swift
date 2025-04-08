import Foundation
import CoreData

/// Extension für berechnete Eigenschaften der Jahresabrechnung
extension AnnualBilling {
    // Hier können zusätzliche Methoden und berechnete Eigenschaften hinzugefügt werden
    // aber KEINE doppelte Klassendeklaration
    
    // Beispiel für eine berechnete Eigenschaft:
    var formattedYear: String {
        return "Jahr \(year)"
    }
}

/// Extension für berechnete Eigenschaften der Wohnungsabrechnung
extension ApartmentBilling {
    var balanceStatus: String {
        let balance = totalPaidAmount - totalCosts
        return balance >= 0 ? "Guthaben" : "Nachzahlung"
    }
}