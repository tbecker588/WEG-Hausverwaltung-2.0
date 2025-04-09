import CoreData
import Foundation
import SwiftUI

// Kategorien für Verteilungsschlüssel
enum DistributionCategory: String, Codable, CaseIterable {
    case mea = "MEA (Miteigentumsanteil)"
    case commonAreas = "Gemeinschaftsflächen"
    case wasteDisposal = "Müllentsorgung"
    case other = "Sonstige"
}

// Verteilungstypen
enum DistributionType: String, Codable, CaseIterable {
    case fixedTotal = "1/1000"
    case perUnit = "1/6"
    case perPerson = "Personenbasiert"
    case areaProportional = "Nach Wohnfläche"
    case equalShare = "Gleichmäßig"
}

extension DistributionSetting {
    static func loadSettings() -> [DistributionSetting] {
        // Implementation hier
        []
    }
}

struct DistributionSettingsView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DistributionSetting.name, ascending: true)],
        animation: .default
    )
    private var settings: FetchedResults<DistributionSetting>

    var body: some View {
        NavigationView {
            List {
                ForEach(settings) { setting in
                    SettingRow(setting: setting)
                }
            }
            .navigationTitle("Verteilungsschlüssel")
        }
    }
}

struct SettingRow: View {
    let setting: DistributionSetting

    var body: some View {
        HStack {
            Text(setting.name)
            Spacer()
            Text("\(setting.value, specifier: "%.2f")")
        }
    }
}

struct DistributionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DistributionSettingsView()
        }
    }
}
