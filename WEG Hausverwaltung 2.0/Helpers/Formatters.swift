import Foundation
import SwiftUI

/// Zentrale Formatierungs-Utilities für die gesamte App
///
/// Verwendet Singleton-Pattern für optimierte Performance durch
/// wiederverwendete Formatter-Instanzen.
///
/// Beispiel:
/// ```swift
/// let amount = 1234.56
/// let formatted = Formatters.formatCurrency(amount) // "1.234,56 €"
/// ```
enum Formatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()

    static func formatCurrency(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "0,00 €"
    }

    static func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - View Components

// Diese Komponenten sollten in separate View-Dateien ausgelagert werden

/// Karte für die Wohnungsabrechnung
struct ApartmentBillingCard: View {
    var owner: Owner
    var billing: ApartmentBilling

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(owner.fullName)
                        .font(.headline)
                    Text("Wohnung \(owner.apartmentNumber ?? "-")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(billing.finalBalance > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 70, height: 70)

                    VStack(spacing: 0) {
                        Text(billing.finalBalance > 0 ? "Guthaben" : "Nachzahlung")
                            .font(.caption2)
                            .foregroundColor(billing.finalBalance > 0 ? .green : .red)

                        Text(Formatters.formatCurrency(abs(billing.finalBalance)))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(billing.finalBalance > 0 ? .green : .red)
                    }
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Wasserkosten:", value: Formatters.formatCurrency(billing.waterCost))
                    InfoRow(label: "Heizkosten:", value: Formatters.formatCurrency(billing.heatingCost))
                    InfoRow(label: "Gaskosten:", value: Formatters.formatCurrency(billing.gasCost))

                    if let wasteCost = billing.wasteCost, wasteCost > 0 {
                        InfoRow(label: "Müllkosten:", value: Formatters.formatCurrency(wasteCost))
                    }

                    if let commonAreasCost = billing.commonAreasCost, commonAreasCost > 0 {
                        InfoRow(label: "Allgemeinkosten:", value: Formatters.formatCurrency(commonAreasCost))
                    }

                    Divider()

                    InfoRow(
                        label: "Gesamtkosten:",
                        value: Formatters.formatCurrency(billing.totalCosts),
                        isHighlighted: true
                    )
                    InfoRow(
                        label: "Gezahlte Vorauszahlung:",
                        value: Formatters.formatCurrency(billing.totalPaidAmount),
                        isHighlighted: true
                    )
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
