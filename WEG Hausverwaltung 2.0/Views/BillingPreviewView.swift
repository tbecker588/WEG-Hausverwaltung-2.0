import CoreData
import SwiftUI

struct BillingPreviewView: View {
    // CoreData-Kontext und Fetching-Eigenschaften
    @Environment(\.managedObjectContext)
    private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AnnualBilling.year, ascending: false)],
        animation: .default
    )
    private var annualBillings: FetchedResults<AnnualBilling>

    // Ausgewählte Abrechnung
    @State
    private var selectedBilling: AnnualBilling?
    @State
    private var selectedOwner: Owner?

    var body: some View {
        VStack {
            // Jahresauswahl
            if !annualBillings.isEmpty {
                Picker("Abrechnungsjahr", selection: $selectedBilling) {
                    ForEach(annualBillings) { billing in
                        Text("\(billing.year)").tag(billing as AnnualBilling?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }

            // Eigentümerauswahl
            if let billing = selectedBilling {
                ownerSelectionView(for: billing)
            }

            // Abrechnungsdetails
            if let owner = selectedOwner, let billing = selectedBilling {
                billingDetailsView(for: owner, in: billing)
            }
        }
        .navigationTitle("Abrechnung")
        .onAppear {
            // Automatisch das aktuelle Jahr auswählen
            selectedBilling = annualBillings.first
        }
    }

    // Eigentümer-Auswahlansicht
    private func ownerSelectionView(for billing: AnnualBilling) -> some View {
        VStack {
            Picker("Eigentümer", selection: $selectedOwner) {
                ForEach(fetchOwners(for: billing)) { owner in
                    Text("\(owner.firstName) \(owner.lastName)").tag(owner as Owner?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
        }
    }

    // Abrechnungsdetails-Ansicht
    private func billingDetailsView(for owner: Owner, in billing: AnnualBilling) -> some View {
        // Hole die spezifische Wohnungsabrechnung
        guard let apartmentBilling = fetchApartmentBilling(for: owner, in: billing) else {
            return AnyView(Text("Keine Abrechnung gefunden"))
        }

        return AnyView(
            Form {
                // Wasserdaten
                Section(header: Text("Wasser")) {
                    DetailRow(
                        title: "Gesamtverbrauch",
                        value: "\(String(format: "%.2f", apartmentBilling.waterConsumption)) m³",
                        cost: apartmentBilling.waterCost
                    )
                }

                // Gasdaten
                Section(header: Text("Gas")) {
                    DetailRow(
                        title: "Gesamtverbrauch",
                        value: "\(String(format: "%.2f", apartmentBilling.gasConsumption)) kWh",
                        cost: apartmentBilling.gasCost
                    )
                }

                // Heizung
                Section(header: Text("Heizung")) {
                    DetailRow(
                        title: "Gesamtverbrauch",
                        value: "\(String(format: "%.2f", apartmentBilling.heatingConsumption)) kWh",
                        cost: apartmentBilling.heatingCost
                    )
                }

                // Wohngeld und Saldo
                Section(header: Text("Abrechnung")) {
                    HStack {
                        Text("Monatliche Vorauszahlung")
                        Spacer()
                        Text(String(format: "%.2f €", apartmentBilling.totalMonthlyFee * 12))
                    }

                    HStack {
                        Text("Gesamtkosten")
                        Spacer()
                        Text(String(
                            format: "%.2f €",
                            apartmentBilling.waterCost +
                                apartmentBilling.gasCost +
                                apartmentBilling.heatingCost
                        ))
                    }

                    HStack {
                        Text("Saldo")
                        Spacer()
                        Text(String(format: "%.2f €", apartmentBilling.finalBalance))
                            .foregroundColor(apartmentBilling.finalBalance >= 0 ? .green : .red)
                    }
                }

                // Export-Optionen
                Section {
                    Button("Als PDF exportieren") {
                        exportPDF(for: owner, in: billing)
                    }
                }
            }
        )
    }

    // Hilfsfunktion zum Abrufen von Eigentümern
    private func fetchOwners(for billing: AnnualBilling) -> [Owner] {
        let request = NSFetchRequest<Owner>(entityName: "Owner")
        request.predicate = NSPredicate(format: "ANY apartmentBillings.annualBilling == %@", billing)

        do {
            return try context.fetch(request)
        } catch {
            print("Fehler beim Abrufen der Eigentümer: \(error)")
            return []
        }
    }

    // Hilfsfunktion zum Abrufen der Wohnungsabrechnung
    private func fetchApartmentBilling(for owner: Owner, in billing: AnnualBilling) -> ApartmentBilling? {
        let request = NSFetchRequest<ApartmentBilling>(entityName: "ApartmentBilling")
        request.predicate = NSPredicate(format: "owner == %@ AND annualBilling == %@", owner, billing)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Fehler beim Abrufen der Wohnungsabrechnung: \(error)")
            return nil
        }
    }

    // PDF-Export-Funktion
    private func exportPDF(for owner: Owner, in billing: AnnualBilling) {
        // TODO: Implementierung des PDF-Exports
        // Könnte eine Vorschau oder direkten Export beinhalten
        print("PDF-Export für \(owner.firstName) \(owner.lastName) im Jahr \(billing.year)")
    }
}

// Hilfs-Komponente für Detailzeilen
struct DetailRow: View {
    let title: String
    let value: String
    let cost: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(String(format: "%.2f €", cost))
        }
    }
}

// Vorschau-Struktur
struct BillingPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BillingPreviewView()
                .environment(\.managedObjectContext, CoreDataStack.shared.context)
        }
    }
}
