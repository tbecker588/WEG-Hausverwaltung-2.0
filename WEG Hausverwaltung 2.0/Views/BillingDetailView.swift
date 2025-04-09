import CoreData
import SwiftUI

struct BillingDetailView: View {
    let billing: NSManagedObject // Verwende NSManagedObject statt AnnualBilling

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Überschrift (korrigiere die fehlerhafte Zeile mit dem vollständigen String)
                Text("Jahresabrechnung \(billing.value(forKey: "year") as? Int16 ?? 0)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Grunddaten
                VStack(alignment: .leading, spacing: 10) {
                    Text("Grunddaten").font(.headline)

                    HStack {
                        Text("Abrechnungsjahr:")
                        Spacer()
                        Text("\(billing.value(forKey: "year") as? Int16 ?? 0)")
                    }

                    HStack {
                        Text("Erstellungsdatum:")
                        Spacer()
                        Text(formattedDate(billing.value(forKey: "creationDate") as? Date ?? Date()))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Wasserverbrauch
                VStack(alignment: .leading, spacing: 10) {
                    Text("Wasserverbrauch").font(.headline)

                    HStack {
                        Text("Gesamtverbrauch:")
                        Spacer()
                        Text(
                            "\(String(format: "%.1f", billing.value(forKey: "totalWaterConsumption") as? Double ?? 0.0)) m³"
                        )
                    }

                    HStack {
                        Text("Gesamtkosten:")
                        Spacer()
                        Text(formatCurrency(billing.value(forKey: "totalWaterCost") as? Double ?? 0.0))
                    }

                    HStack {
                        Text("Preis pro m³:")
                        Spacer()
                        Text(formatCurrency(billing.value(forKey: "waterCostPerCubicMeter") as? Double ?? 0.0))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Gasverbrauch
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gasverbrauch").font(.headline)

                    HStack {
                        Text("Gesamtverbrauch:")
                        Spacer()
                        Text(
                            "\(String(format: "%.1f", billing.value(forKey: "totalGasConsumption") as? Double ?? 0.0)) kWh"
                        )
                    }

                    HStack {
                        Text("Gesamtkosten:")
                        Spacer()
                        Text(formatCurrency(billing.value(forKey: "totalGasCost") as? Double ?? 0.0))
                    }

                    HStack {
                        Text("Preis pro kWh:")
                        Spacer()
                        Text(formatCurrency(billing.value(forKey: "gasCostPerKWh") as? Double ?? 0.0))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Wohnungsabrechnungen
                if let apartmentBillings = billing.value(forKey: "apartmentBillings") as? Set<NSManagedObject>,
                   !apartmentBillings.isEmpty
                {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Wohnungsabrechnungen").font(.headline)

                        ForEach(
                            Array(apartmentBillings)
                                .sorted {
                                    ($0.value(forKey: "owner") as? NSManagedObject)?
                                        .value(forKey: "lastName") as? String ?? "" <
                                        ($1.value(forKey: "owner") as? NSManagedObject)?
                                        .value(forKey: "lastName") as? String ?? ""
                                },
                            id: \.objectID
                        ) { apartmentBilling in
                            NavigationLink(destination: ApartmentBillingView(billing: apartmentBilling)) {
                                HStack {
                                    Text(
                                        "\((apartmentBilling.value(forKey: "owner") as? NSManagedObject)?.value(forKey: "fullName") as? String ?? "Unbekannt")"
                                    )
                                    Spacer()
                                    Text(formatCurrency(apartmentBilling.value(forKey: "totalCosts") as? Double ?? 0.0))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Jahresabrechnung")
    }

    // Hilfsfunktionen
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }
}

// Simple ApartmentBillingView
struct ApartmentBillingView: View {
    let billing: NSManagedObject // Verwende NSManagedObject statt ApartmentBilling

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Wohnungsabrechnung")
                    .font(.title)
                    .fontWeight(.bold)

                if let owner = billing.value(forKey: "owner") as? NSManagedObject {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Eigentümer").font(.headline)
                        Text(owner.value(forKey: "fullName") as? String ?? "")
                        if let apartment = owner.value(forKey: "apartmentNumber") as? String {
                            Text("Wohnung: \(apartment)")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Verbräuche
                VStack(alignment: .leading, spacing: 10) {
                    Text("Verbräuche").font(.headline)

                    HStack {
                        Text("Wasser:")
                        Spacer()
                        Text(
                            "\(String(format: "%.1f", billing.value(forKey: "waterConsumption") as? Double ?? 0.0)) m³"
                        )
                    }

                    HStack {
                        Text("Gas:")
                        Spacer()
                        Text("\(String(format: "%.1f", billing.value(forKey: "gasConsumption") as? Double ?? 0.0)) kWh")
                    }

                    HStack {
                        Text("Heizung:")
                        Spacer()
                        Text(
                            "\(String(format: "%.1f", billing.value(forKey: "heatingConsumption") as? Double ?? 0.0)) kWh"
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Wohnungsabrechnung")
    }
}
