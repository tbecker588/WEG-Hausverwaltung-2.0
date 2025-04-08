import Foundation
import CoreData

/// Verteilungsschlüssel für Kosten
enum DistributionKeyEnum: Codable {
    case fixedTotal(total: Double)
    case perUnit(units: Double)
    case perPerson(totalPersons: Int, ownerPersons: Int)
    case areaProportional
    case equalShare
    
    func calculateShare(totalAmount: Double, owner: Owner, totalApartments: Int = 0) -> Double {
        switch self {
        case .fixedTotal(let total):
            return (1.0 / total) * totalAmount
        
        case .perUnit(let units):
            return (1.0 / units) * totalAmount
        
        case .perPerson(let totalPersons, let ownerPersons):
            return (Double(ownerPersons) / Double(totalPersons)) * totalAmount
        
        case .areaProportional:
            return (owner.ownershipShare / 100.0) * totalAmount
        
        case .equalShare:
            return totalAmount / Double(max(1, totalApartments))
        }
    }
    
    var description: String {
        switch self {
        case .fixedTotal(let total):
            return "1/\(total)"
        case .perUnit(let units):
            return "1/\(units)"
        case .perPerson(let totalPersons, let ownerPersons):
            return "\(ownerPersons)/\(totalPersons)"
        case .areaProportional:
            return "Nach Wohnfläche"
        case .equalShare:
            return "Gleichmäßig"
        }
    }
    
    static func fromSetting(_ setting: DistributionSetting, owner: Owner) -> DistributionKeyEnum {
        switch setting.type {
        case .fixedTotal:
            return .fixedTotal(total: setting.value)
        case .perUnit:
            return .perUnit(units: setting.value)
        case .perPerson:
            return .perPerson(
                totalPersons: Int(exactly: setting.value) ?? 0, 
                ownerPersons: owner.occupantCount
            )
        case .areaProportional:
            return .areaProportional
        case .equalShare:
            return .equalShare
        }
    }
}

// MARK: - Beispieldaten für Tests/Preview
extension DistributionKeyEnum {
    static var examples: [DistributionKeyEnum] {
        [
            .fixedTotal(total: 1000),
            .perUnit(units: 6),
            .perPerson(totalPersons: 10, ownerPersons: 2),
            .areaProportional,
            .equalShare
        ]
    }
}

struct DistributionKey: Identifiable {
    var id = UUID()
    var name: String
    var distribution: [AppOwner: Double]  // Verwende den Typ-Alias
    // weitere Eigenschaften...
}