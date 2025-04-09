/**
 * @brief   Übersichtskarte für Verbrauchswerte
 * @author  [IhrName]
 * @date    2024-04-08
 */

import SwiftUI

struct ConsumptionRow: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value, specifier: "%.2f") \(unit)")
        }
        .padding(.horizontal)
    }
}

struct ConsumptionRow_Previews: PreviewProvider {
    static var previews: some View {
        ConsumptionRow(title: "Test", value: 123.45, unit: "kWh")
    }
}

struct ConsumptionOverviewCardView: View {
    let waterConsumption: Double
    let gasConsumption: Double
    let previousWaterConsumption: Double?
    let previousGasConsumption: Double?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ConsumptionRow(
                title: "Wasser",
                value: waterConsumption,
                unit: "m³"
            )

            ConsumptionRow(
                title: "Gas",
                value: gasConsumption,
                unit: "kWh"
            )
        }
        .padding(DesignSystem.Spacing.medium)
    }
}
