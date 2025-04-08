import SwiftUI

/// Übersichtskarte für Verbrauchsdaten
struct ConsumptionOverviewCard: View {
    // MARK: - Properties
    let waterConsumption: Double
    let gasConsumption: Double
    let previousWaterConsumption: Double?
    let previousGasConsumption: Double?
    
    // MARK: - Berechnete Eigenschaften
    private var waterDifference: Double? {
        guard let previous = previousWaterConsumption else { return nil }
        return waterConsumption - previous
    }
    
    private var gasDifference: Double? {
        guard let previous = previousGasConsumption else { return nil }
        return gasConsumption - previous
    }
    
    // MARK: - Body
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                consumptionRow(
                    title: "Wasserverbrauch",
                    value: waterConsumption,
                    unit: "m³",
                    difference: waterDifference
                )
                
                Divider()
                
                consumptionRow(
                    title: "Gasverbrauch",
                    value: gasConsumption,
                    unit: "kWh",
                    difference: gasDifference
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verbrauchsübersicht")
    }
    
    // MARK: - Helper Views
    private func consumptionRow(
        title: String,
        value: Double,
        unit: String,
        difference: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.title3)
                    .bold()
                
                if let diff = difference {
                    HStack(spacing: 4) {
                        Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down")
                        Text("\(abs(diff), specifier: "%.1f")")
                    }
                    .foregroundColor(diff >= 0 ? .red : .green)
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Preview
struct ConsumptionOverviewCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConsumptionOverviewCard(
                waterConsumption: 120.5,
                gasConsumption: 5000,
                previousWaterConsumption: 110.0,
                previousGasConsumption: 4800
            )
            
            ConsumptionOverviewCard(
                waterConsumption: 95.0,
                gasConsumption: 4200,
                previousWaterConsumption: nil,
                previousGasConsumption: nil
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
