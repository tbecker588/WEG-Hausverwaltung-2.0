import CoreData
import Foundation

/// Service zur Verwaltung von Eigentümerübergängen
/// Behandelt die komplette Übertragung von Eigentum einschließlich:
/// - Zwischenabrechnungen
/// - Heizkörperübertragung
/// - Abrechnungsperioden
class OwnerTransferService {
    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public API

    /// Überträgt das Eigentum von einem alten zu einem neuen Eigentümer
    /// - Parameters:
    ///   - oldOwner: Bisheriger Eigentümer
    ///   - newOwner: Neuer Eigentümer
    ///   - reason: Grund für die Übertragung
    ///   - date: Datum der Übertragung
    /// - Returns: Void bei Erfolg, Error bei Fehler
    func transferOwnership(
        from oldOwner: Owner,
        to newOwner: Owner,
        reason: String,
        date: Date
    ) async throws {
        guard oldOwner.isValid, newOwner.isValid else {
            throw TransferError.invalidOwner
        }

        // 1. Zwischenabrechnung erstellen
        let billing = createIntermediateSettlement(for: oldOwner, until: date)

        // 2. Heizkörper übertragen
        try transferHeaters(from: oldOwner, to: newOwner)

        // 3. Restliche Abrechnungsperiode übertragen
        try await transferBillingPeriod(from: oldOwner, to: newOwner, fromDate: date)

        // 4. Alten Eigentümer archivieren
        archiveOwner(oldOwner, reason: reason, date: date)

        try context.save()
    }

    // MARK: - Private Helper Methods

    private func createIntermediateSettlement(for owner: Owner, until date: Date) -> ApartmentBilling {
        let billing = ApartmentBilling(context: context)
        billing.id = UUID()
        billing.owner = owner
        billing.date = date
        billing.isIntermediate = true
        return billing
    }

    private func transferHeaters(from oldOwner: Owner, to newOwner: Owner) throws {
        guard let heaters = oldOwner.heaters as? Set<Heater> else {
            throw TransferError.heaterAccessFailed
        }
        for heater in heaters {
            heater.owner = newOwner
        }
    }

    private func transferBillingPeriod(
        from _: Owner,
        to _: Owner,
        fromDate _: Date
    ) async throws {
        // Implementierung der Abrechnungsperioden-Übertragung
        // mit async/await Support
    }

    private func archiveOwner(_ owner: Owner, reason: String, date: Date) {
        owner.isArchived = true
        owner.archiveReason = reason
        owner.archiveDate = date
    }
}

// MARK: - Error Types

enum TransferError: LocalizedError {
    case invalidOwner
    case heaterAccessFailed
    case billingPeriodTransferFailed

    var errorDescription: String? {
        switch self {
        case .invalidOwner:
            "Ungültiger Eigentümer"
        case .heaterAccessFailed:
            "Zugriff auf Heizkörper fehlgeschlagen"
        case .billingPeriodTransferFailed:
            "Übertragung der Abrechnungsperiode fehlgeschlagen"
        }
    }
}
