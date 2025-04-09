import Foundation

enum BillingStatus: String {
    case pending = "Ausstehend"
    case inProgress = "In Bearbeitung"
    case completed = "Abgeschlossen"
}

enum VerificationStatus: String {
    case unverified = "Ungeprüft"
    case verified = "Geprüft"
    case rejected = "Abgelehnt"
}
