import Foundation
import CoreData

// MARK: - App-spezifische Modelle
struct AppOwner: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String?
    var ownershipShare: Double
    
    // Hashable Konformität
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppOwner, rhs: AppOwner) -> Bool {
        lhs.id == rhs.id
    }
    
    // Initialisierung aus Core Data Owner
    init(from owner: Owner) {
        self.id = owner.id ?? UUID()
        self.firstName = owner.firstName ?? ""
        self.lastName = owner.lastName ?? ""
        self.email = owner.email
        self.ownershipShare = owner.ownershipShare
    }
}

struct Apartment: Identifiable {
    let id: UUID
    var number: String
    var size: Double
    var owner: Owner?
    
    init(id: UUID = UUID(), number: String, size: Double, owner: Owner? = nil) {
        self.id = id
        self.number = number
        self.size = size
        self.owner = owner
    }
}

// MARK: - Hilfsfunktionen
extension AppOwner {
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

extension Apartment {
    var displayName: String {
        "Wohnung \(number)"
    }
}