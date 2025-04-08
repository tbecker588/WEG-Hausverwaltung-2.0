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
/// let formatted = Formatters.currency(amount) // "1.234,56 €"
/// ```
enum Formatters {
    // MARK: - Private Formatter
    
    /// Währungs-Formatter für Euro mit deutscher Lokalisierung
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    /// Datums-Formatter im deutschen Format (TT.MM.YYYY)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    /// Prozent-Formatter mit einer Nachkommastelle
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }()
    
    // MARK: - Öffentliche Formatierungsmethoden
    
    /// Formatiert einen Geldbetrag als deutsche Währung
    /// - Parameter amount: Der zu formatierende Betrag
    /// - Returns: Formatierter String (z.B. "123,45 €")
    static func currency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "€0,00"
    }
    
    /// Formatiert ein Datum im deutschen Format
    /// - Parameter date: Das zu formatierende Datum
    /// - Returns: Formatierter String (z.B. "01.04.2025")
    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    /// Formatiert einen Verbrauchswert mit Einheit
    /// - Parameters:
    ///   - value: Der Verbrauchswert
    ///   - unit: Die Einheit (z.B. "m³" oder "kWh")
    /// - Returns: Formatierter String (z.B. "123,4 m³")
    static func consumption(_ value: Double, unit: String) -> String {
        String(format: "%.1f %@", value, unit)
    }
    
    /// Formatiert einen Dezimalwert als Prozentsatz
    /// - Parameter value: Der Wert (0-100)
    /// - Returns: Formatierter String (z.B. "42,5%")
    static func percentage(_ value: Double) -> String {
        percentFormatter.string(from: NSNumber(value: value/100)) ?? "0%"
    }
}

// MARK: - UI-Komponenten sollten in separate Dateien verschoben werden
// TODO: Verschiebe alle View-Komponenten in eigene Dateien im Views/Components Verzeichnis

/// Zeile für Informationsanzeige in Abrechnungen
struct InfoRow: View {
    var label: String
    var value: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? .primary : .secondary)
        }
    }
}

/// Karte für die Verbrauchsübersicht
struct ConsumptionOverviewCard: View {
    var title: String
    var consumption: Double
    var cost: Double
    var unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", consumption)) \(unit)")
                        .font(.title2)
                    Text("Verbrauch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(Formatters.currency(cost))
                        .font(.title2)
                    Text("Kosten")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

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
                        
                        Text(Formatters.currency(abs(billing.finalBalance)))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(billing.finalBalance > 0 ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Wasserkosten:", value: Formatters.currency(billing.waterCost))
                    InfoRow(label: "Heizkosten:", value: Formatters.currency(billing.heatingCost))
                    InfoRow(label: "Gaskosten:", value: Formatters.currency(billing.gasCost))
                    
                    if let wasteCost = billing.wasteCost, wasteCost > 0 {
                        InfoRow(label: "Müllkosten:", value: Formatters.currency(wasteCost))
                    }
                    
                    if let commonAreasCost = billing.commonAreasCost, commonAreasCost > 0 {
                        InfoRow(label: "Allgemeinkosten:", value: Formatters.currency(commonAreasCost))
                    }
                    
                    Divider()
                    
                    InfoRow(
                        label: "Gesamtkosten:",
                        value: Formatters.currency(billing.totalCosts),
                        isHighlighted: true
                    )
                    InfoRow(
                        label: "Gezahlte Vorauszahlung:",
                        value: Formatters.currency(billing.totalPaidAmount),
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

/// Karte für die Zusammenfassung einer Abrechnung
struct BillingSummaryCard: View {
    var annualBilling: AnnualBilling
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jahresabrechnung \(annualBilling.year)")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            // Wasserverbrauch
            HStack {
                Text("Wasserverbrauch:")
                Spacer()
                Text(Formatters.consumption(annualBilling.totalWaterConsumption, unit: "m³"))
            }
            
            // Wasserkosten
            HStack {
                Text("Wasserkosten:")
                Spacer()
                Text(Formatters.currency(annualBilling.totalWaterCost))
            }
            
            // Gasverbrauch
            HStack {
                Text("Gasverbrauch:")
                Spacer()
                Text(Formatters.consumption(annualBilling.totalGasConsumption, unit: "kWh"))
            }
            
            // Gaskosten
            HStack {
                Text("Gaskosten:")
                Spacer()
                Text(Formatters.currency(annualBilling.totalGasCost))
            }
            
            Divider()
            
            // Gesamtkosten
            HStack {
                Text("Gesamtkosten:")
                    .fontWeight(.bold)
                Spacer()
                Text(Formatters.currency(annualBilling.totalWaterCost + annualBilling.totalGasCost))
                    .fontWeight(.bold)
            }
            
            // Status und Erstellungsdatum
            HStack {
                Label(
                    annualBilling.isFinalized ? "Abgeschlossen" : "In Bearbeitung",
                    systemImage: annualBilling.isFinalized ? "checkmark.seal.fill" : "exclamationmark.triangle"
                )
                .foregroundColor(annualBilling.isFinalized ? .green : .orange)
                .font(.caption)
                
                Spacer()
                
                Text("Erstellt am \(Formatters.date(annualBilling.creationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
