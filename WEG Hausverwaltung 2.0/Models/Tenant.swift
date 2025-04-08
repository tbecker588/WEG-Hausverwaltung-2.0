import Foundation
import CoreData

extension Tenant {
    // MARK: - Berechnete Eigenschaften
    
    /// Vollständiger Name des Mieters
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Beispieldaten für Vorschau
    static var example: Tenant {
        let context = CoreDataStack.preview.context
        let tenant = Tenant(context: context)
        tenant.id = UUID()
        tenant.firstName = "Erika"
        tenant.lastName = "Musterfrau"
        tenant.phoneNumber = "0123-456789"
        tenant.startDate = Date()
        tenant.owner = Owner.example
        
        try? context.save()
        return tenant
    }
}