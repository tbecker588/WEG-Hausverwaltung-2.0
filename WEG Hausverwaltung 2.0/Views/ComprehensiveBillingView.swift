import SwiftUI
import CoreData

struct ComprehensiveBillingView: View {
    @Environment(\.managedObjectContext) private var context
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AnnualBilling.year, ascending: false)],
        animation: .default)
    private var billings: FetchedResults<AnnualBilling>
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        VStack {
            // Jahr-Auswahl
            Picker("Abrechnungsjahr", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Hauptinhalt
            if let billing = billingForSelectedYear {
                ScrollView {
                    VStack(spacing: 20) {
                        // Zusammenfassung
                        BillingSummaryCard(billing: billing)
                        
                        // Verbrauchsübersicht
                        ConsumptionOverviewCard(billing: billing)
                        
                        // Kostendetails pro Eigentümer
                        ForEach(Array(billing.apartmentBillings ?? []), id: \.id) { apartmentBilling in
                            ApartmentBillingCard(apartmentBilling: apartmentBilling)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Keine Abrechnung verfügbar",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Für das Jahr \(selectedYear) gibt es noch keine Abrechnung.")
                )
                
                Button("Jahresabrechnung erstellen") {
                    // Navigation zur Abrechnungserstellung
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle("Gesamtabrechnung")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: exportToPDF) {
                    Label("Exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(billingForSelectedYear == nil)
            }
        }
    }
    
    // Verfügbare Jahre für die Auswahl
    private var availableYears: [Int] {
        var years = billings.map { Int($0.year) }
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Füge das aktuelle Jahr hinzu, falls noch nicht vorhanden
        if !years.contains(currentYear) {
            years.append(currentYear)
        }
        
        return years.sorted(by: >)  // Absteigend sortieren
    }
    
    // Die Abrechnung für das ausgewählte Jahr
    private var billingForSelectedYear: AnnualBilling? {
        return billings.first { $0.year == Int16(selectedYear) }
    }
    
    // PDF-Export-Funktion
    private func exportToPDF() {
        // Hier PDF-Export implementieren
        print("PDF wird exportiert...")
    }
}

// MARK: - Komponenten für die Comprehensive Billing View

struct BillingSummaryCard: View {
    let billing: AnnualBilling
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Jahresabrechnung \(billing.year)")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            // Gesamtkosten
            Group {
                InfoRow(title: "Wasserkosten gesamt", value: formatCurrency(billing.totalWaterCost))
                InfoRow(title: "Gaskosten gesamt", value: formatCurrency(billing.totalGasCost))
                
                // Weitere Kostenarten könnten hier hinzugefügt werden
                
                Divider()
                
                InfoRow(title: "Gesamtkosten", 
                        value: formatCurrency(billing.totalWaterCost + billing.totalGasCost),
                        isBold: true)
            }
            
            // Status und Erstellungsdatum
            HStack {
                Label(
                    billing.isFinalized ? "Abgeschlossen" : "In Bearbeitung",
                    systemImage: billing.isFinalized ? "checkmark.seal.fill" : "exclamationmark.triangle"
                )
                .foregroundColor(billing.isFinalized ? .green : .orange)
                .font(.caption)
                
                Spacer()
                
                Text("Erstellt am \(formatDate(billing.creationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}