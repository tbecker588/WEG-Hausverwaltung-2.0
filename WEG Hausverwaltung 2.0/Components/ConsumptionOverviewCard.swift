/**
 * @brief   Übersichtskarte für Verbrauchswerte
 * @author  [IhrName]
 * @date    2024-04-08
 */

import SwiftUI

struct ConsumptionOverviewCardView: View {
    let waterConsumption: Double
    let gasConsumption: Double
    let previousWaterConsumption: Double?
    let previousGasConsumption: Double?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ConsumptionRow(
                title: "Wasser",
                consumption: String(format: "%.1f", waterConsumption),
                cost: "0,00",
                unit: "m³"
            )

            ConsumptionRow(
                title: "Gas",
                consumption: String(format: "%.1f", gasConsumption),
                cost: "0,00",
                unit: "kWh"
            )
        }
        .padding(DesignSystem.Spacing.medium)
    }
}
