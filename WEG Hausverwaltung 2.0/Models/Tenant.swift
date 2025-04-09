/**
 * @brief   Mieter-Model
 * @author  [IhrName]
 * @date    2024-04-08
 */

import CoreData
import Foundation

@objc(Tenant)
public class Tenant: NSManagedObject {
    @NSManaged
    private var primitiveFirstName: String?
    @NSManaged
    private var primitiveLastName: String?

    var displayName: String {
        "\(primitiveFirstName ?? "") \(primitiveLastName ?? "")"
    }
}

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
