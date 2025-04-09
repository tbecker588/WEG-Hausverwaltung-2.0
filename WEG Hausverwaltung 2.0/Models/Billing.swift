/**
 * @class   Billing
 * @brief   Abrechnungsmodell für WEG-Abrechnungen
 *
 * @details Verwaltet die Abrechnungsdaten für einen bestimmten Zeitraum
 *          und einen spezifischen Eigentümer.
 *
 * @author  [IhrName]
 * @date    2024-04-08
 * @version 1.0
 */

import CoreData
import Foundation

@objc(Billing)
public class Billing: NSManagedObject, Identifiable {
    // MARK: - Properties

    @NSManaged
    private var primitiveId: UUID?
    @NSManaged
    private var primitiveYear: Int16
    @NSManaged
    private var primitiveIsVerified: Bool
    @NSManaged
    private var primitiveVerifiedBy: String?
    @NSManaged
    private var primitiveVerifiedAt: Date?

    // MARK: - Public Interface

    public var year: Int16 {
        get { primitiveYear }
        set { primitiveYear = newValue }
    }

    public var isVerified: Bool {
        get { primitiveIsVerified }
        set { primitiveIsVerified = newValue }
    }

    // MARK: - Validation

    public func validate() -> Bool {
        guard year >= 2000,
              year <= Calendar.current.component(.year, from: Date())
        else {
            return false
        }
        return true
    }

    // MARK: - Validierung

    var isValid: Bool {
        year > 0
    }

    // MARK: - Berechnete Eigenschaften

    var status: VerificationStatus {
        if isVerified {
            return .verified(verifier: verifiedBy ?? "Unbekannt", date: verifiedAt ?? Date())
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
        guard let date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    func paymentReceived(byUser _: String, atDate _: Date) {
        // Implementierung der Methode
    }
}

// MARK: - Core Data Properties

public extension Billing {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<Billing> {
        NSFetchRequest<Billing>(entityName: "Billing")
    }

    @NSManaged
    var verifiedBy: String?
    @NSManaged
    var verifiedAt: Date?
}

// MARK: - Verification Status

extension Billing {
    enum VerificationStatus: Equatable {
        case pending
        case verified(verifier: String, date: Date) // Parameter umbenannt

        var description: String {
            switch self {
            case .pending:
                "Prüfung ausstehend"
            case let .verified(verifier, date):
                "Geprüft von \(verifier) am \(date.formatted(date: .abbreviated, time: .shortened))"
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
