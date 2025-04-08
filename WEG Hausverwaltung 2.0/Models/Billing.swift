import Foundation
import CoreData

@objc(Billing)
public class Billing: NSManagedObject {
    // MARK: - Validierung
    
    var isValid: Bool {
        year > 0
    }
    
    // MARK: - Berechnete Eigenschaften
    
    var status: VerificationStatus {
        if isVerified {
            return .verified(by: verifiedBy ?? "Unbekannt", at: verifiedAt ?? Date())
        }
        return .pending
    }
    
    var formattedYear: String {
        "Jahr \(year)"
    }
    
    var verificationInfo: String {
        guard isVerified else { return "Nicht geprüft" }
        return "Geprüft von \(verifiedBy ?? "Unbekannt") am \(formattedDate(verifiedAt))"
    }
    
    // MARK: - Hilfsmethoden
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

// MARK: - Core Data Properties
extension Billing {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Billing> {
        return NSFetchRequest<Billing>(entityName: "Billing")
    }
    
    @NSManaged public var year: Int16
    @NSManaged public var isVerified: Bool
    @NSManaged public var verifiedBy: String?
    @NSManaged public var verifiedAt: Date?
}

// MARK: - Verification Status
extension Billing {
    enum VerificationStatus: Equatable {
        case pending
        case verified(by: String, at: Date)
        
        var description: String {
            switch self {
            case .pending:
                return "Prüfung ausstehend"
            case .verified(let verifier, let date):
                return "Geprüft von \(verifier) am \(date.formatted(date: .abbreviated, time: .shortened))"
            }
        }
    }
}

// MARK: - Preview Support
extension Billing {
    static var example: Billing {
        let context = PersistenceController.preview.container.viewContext
        let billing = Billing(context: context)
        billing.year = 2025
        billing.isVerified = true
        billing.verifiedBy = "Max Mustermann"
        billing.verifiedAt = Date()
        return billing
    }
    
    static var unverifiedExample: Billing {
        let context = PersistenceController.preview.container.viewContext
        let billing = Billing(context: context)
        billing.year = 2025
        billing.isVerified = false
        return billing
    }
}