import CoreData
import Foundation

/// Verteilungsschlüssel für Kosten
enum DistributionKeyEnum: Codable {
    case fixedTotal(total: Double)
    case perUnit(units: Double)
    case perPerson(totalPersons: Int, ownerPersons: Int)
    case areaProportional
    case equalShare

    func calculateShare(totalAmount: Double, owner: Owner, totalApartments: Int = 0) -> Double {
        switch self {
        case let .fixedTotal(total):
            (1.0 / total) * totalAmount

        case let .perUnit(units):
            (1.0 / units) * totalAmount

        case let .perPerson(totalPersons, ownerPersons):
            (Double(ownerPersons) / Double(totalPersons)) * totalAmount

        case .areaProportional:
            (owner.ownershipShare / 100.0) * totalAmount

        case .equalShare:
            totalAmount / Double(max(1, totalApartments))
        }
    }

    var description: String {
        switch self {
        case let .fixedTotal(total):
            "1/\(total)"
        case let .perUnit(units):
            "1/\(units)"
        case let .perPerson(totalPersons, ownerPersons):
            "\(ownerPersons)/\(totalPersons)"
        case .areaProportional:
            "Nach Wohnfläche"
        case .equalShare:
            "Gleichmäßig"
        }
    }

    static func fromSetting(_ setting: DistributionSetting, owner: Owner) -> DistributionKeyEnum {
        switch setting.type {
        case .fixedTotal:
            .fixedTotal(total: setting.value)
        case .perUnit:
            .perUnit(units: setting.value)
        case .perPerson:
            .perPerson(
                totalPersons: Int(exactly: setting.value) ?? 0,
                ownerPersons: owner.occupantCount
            )
        case .areaProportional:
            .areaProportional
        case .equalShare:
            .equalShare
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
            .equalShare,
        ]
    }
}

struct DistributionKey: Identifiable {
    var id = UUID()
    var name: String
    var distribution: [AppOwner: Double] // Verwende den Typ-Alias
    // weitere Eigenschaften...
}
