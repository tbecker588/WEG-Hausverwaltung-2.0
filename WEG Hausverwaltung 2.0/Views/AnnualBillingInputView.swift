import SwiftUI
import CoreData

struct AnnualBillingInputView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    
    // Wasserzähler-Daten
    @State private var waterTotalConsumption = ""
    @State private var waterTotalCost = ""
    @State private var waterPricePerCubicMeter = ""
    
    // Gaszähler-Daten
    @State private var gasTotalConsumption = ""
    @State private var gasTotalCost = ""
    @State private var gasPricePerKWh = ""
    
    // Heizungsverbrauch
    @State private var heatingTotalConsumption = ""
    
    // Alert-Status
    @State private var showingSaveSuccessAlert = false
    
    var body: some View {
        VStack {
            // Benutzerdefinierte Navigationsleiste
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                }
                
                Spacer()
                
                Text("Jahresabrechnung")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Form {
                // Jahr-Auswahl
                Section(header: Text("Abrechnungsjahr")) {
                    Picker("Jahr", selection: $year) {
                        ForEach((2020...2030), id: \.self) { selectedYear in
                            Text(String(selectedYear)).tag(selectedYear)
                        }
                    }
                }
                
                // Wasserzähler-Sektion
                Section(header: Text("Wasserzähler")) {
                    HStack {
                        Text("Gesamtverbrauch (m³)")
                        Spacer()
                        Button(action: { showNumpad(for: "waterConsumption") }) {
                            Text(waterTotalConsumption.isEmpty ? "Eingeben" : waterTotalConsumption)
                                .foregroundColor(waterTotalConsumption.isEmpty ? .gray : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Gesamtkosten (€)")
                        Spacer()
                        Button(action: { showNumpad(for: "waterCost") }) {
                            Text(waterTotalCost.isEmpty ? "Eingeben" : waterTotalCost)
                                .foregroundColor(waterTotalCost.isEmpty ? .gray : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Preis pro m³ (€)")
                        Spacer()
                        Button(action: { showNumpad(for: "waterPrice") }) {
                            Text(waterPricePerCubicMeter.isEmpty ? "Eingeben" : waterPricePerCubicMeter)
                                .foregroundColor(waterPricePerCubicMeter.isEmpty ? .gray : .primary)
                        }
                    }
                }
                
                // Gaszähler-Sektion
                Section(header: Text("Gaszähler")) {
                    HStack {
                        Text("Gesamtverbrauch (kWh)")
                        Spacer()
                        Button(action: { showNumpad(for: "gasConsumption") }) {
                            Text(gasTotalConsumption.isEmpty ? "Eingeben" : gasTotalConsumption)
                                .foregroundColor(gasTotalConsumption.isEmpty ? .gray : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Gesamtkosten (€)")
                        Spacer()
                        Button(action: { showNumpad(for: "gasCost") }) {
                            Text(gasTotalCost.isEmpty ? "Eingeben" : gasTotalCost)
                                .foregroundColor(gasTotalCost.isEmpty ? .gray : .primary)
                        }
                    }
                    
                    HStack {
                        Text("Preis pro kWh (€)")
                        Spacer()
                        Button(action: { showNumpad(for: "gasPrice") }) {
                            Text(gasPricePerKWh.isEmpty ? "Eingeben" : gasPricePerKWh)
                                .foregroundColor(gasPricePerKWh.isEmpty ? .gray : .primary)
                        }
                    }
                }
                
                // Heizungsverbrauch-Sektion
                Section(header: Text("Heizung")) {
                    HStack {
                        Text("Gesamtverbrauch (kWh)")
                        Spacer()
                        Button(action: { showNumpad(for: "heatingConsumption") }) {
                            Text(heatingTotalConsumption.isEmpty ? "Eingeben" : heatingTotalConsumption)
                                .foregroundColor(heatingTotalConsumption.isEmpty ? .gray : .primary)
                        }
                    }
                }
                
                // Speichern-Button
                Section {
                    Button(action: saveAnnualBilling) {
                        HStack {
                            Spacer()
                            Text("Jahresabrechnung speichern")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid())
                    .foregroundColor(isFormValid() ? .blue : .gray)
                }
            }
        }
        .sheet(isPresented: $showNumpadModal) {
            VStack {
                HStack {
                    Text(numpadTitleForField())
                        .font(.headline)
                    Spacer()
                    Button("Schließen") {
                        showNumpadModal = false
                    }
                }
                .padding()
                
                Divider()
                
                UniversalNumpad(
                    value: $currentNumpadValue, 
                    onConfirm: confirmNumpadEntry
                )
            }
            .background(Color.white)
            .cornerRadius(15)
            .padding()
        }
        .alert(isPresented: $showingSaveSuccessAlert) {
            Alert(
                title: Text("Abrechnung gespeichert"),
                message: Text("Die Jahresabrechnung für \(year) wurde erfolgreich erstellt."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Numpad-Modal-Steuerung
    @State private var showNumpadModal = false
    @State private var currentNumpadValue = ""
    @State private var currentField = ""
    
    private func showNumpad(for field: String) {
        currentField = field
        
        // Aktuellen Wert vorbelegen
        switch field {
        case "waterConsumption": currentNumpadValue = waterTotalConsumption
        case "waterCost": currentNumpadValue = waterTotalCost
        case "waterPrice": currentNumpadValue = waterPricePerCubicMeter
        case "gasConsumption": currentNumpadValue = gasTotalConsumption
        case "gasCost": currentNumpadValue = gasTotalCost
        case "gasPrice": currentNumpadValue = gasPricePerKWh
        case "heatingConsumption": currentNumpadValue = heatingTotalConsumption
        default: currentNumpadValue = ""
        }
        
        showNumpadModal = true
    }
    
    private func numpadTitleForField() -> String {
        switch currentField {
        case "waterConsumption": return "Wasserverbrauch eingeben"
        case "waterCost": return "Wasserkosten eingeben"
        case "waterPrice": return "Wasserpreis pro m³ eingeben"
        case "gasConsumption": return "Gasverbrauch eingeben"
        case "gasCost": return "Gaskosten eingeben"
        case "gasPrice": return "Gaspreis pro kWh eingeben"
        case "heatingConsumption": return "Heizungsverbrauch eingeben"
        default: return "Wert eingeben"
        }
    }
    
    private func confirmNumpadEntry() {
        switch currentField {
        case "waterConsumption": waterTotalConsumption = currentNumpadValue
        case "waterCost": waterTotalCost = currentNumpadValue
        case "waterPrice": waterPricePerCubicMeter = currentNumpadValue
        case "gasConsumption": gasTotalConsumption = currentNumpadValue
        case "gasCost": gasTotalCost = currentNumpadValue
        case "gasPrice": gasPricePerKWh = currentNumpadValue
        case "heatingConsumption": heatingTotalConsumption = currentNumpadValue
        default: break
        }
        
        showNumpadModal = false
    }
    
    // Validierung der Eingaben
    private func isFormValid() -> Bool {
        return !waterTotalConsumption.isEmpty &&
               !waterTotalCost.isEmpty &&
               !waterPricePerCubicMeter.isEmpty &&
               !gasTotalConsumption.isEmpty &&
               !gasTotalCost.isEmpty &&
               !gasPricePerKWh.isEmpty &&
               !heatingTotalConsumption.isEmpty
    }
    
    // Speichern der Jahresabrechnung
    private func saveAnnualBilling() {
        let newBilling = AnnualBilling(context: context)
        newBilling.id = UUID()
        
        // Wasserdaten
        newBilling.year = Int16(year)
        newBilling.totalWaterConsumption = Double(waterTotalConsumption.replacingOccurrences(of: ",", with: ".")) ?? 0
        newBilling.totalWaterCost = Double(waterTotalCost.replacingOccurrences(of: ",", with: ".")) ?? 0
        newBilling.waterCostPerCubicMeter = Double(waterPricePerCubicMeter.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // Gasdaten
        newBilling.totalGasConsumption = Double(gasTotalConsumption.replacingOccurrences(of: ",", with: ".")) ?? 0
        newBilling.totalGasCost = Double(gasTotalCost.replacingOccurrences(of: ",", with: ".")) ?? 0
        newBilling.gasCostPerKWh = Double(gasPricePerKWh.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // Heizungsverbrauch
        newBilling.totalHeatingConsumption = Double(heatingTotalConsumption.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        // Zusätzliche Metadaten
        newBilling.creationDate = Date()
        newBilling.isFinalized = false
        
        do {
            // Berechnung der Jahresabrechnung
            try BillingCalculationService.shared.calculateAnnualBilling(billing: newBilling, context: context)
            
            // Speichern
            try context.save()
            
            // Erfolgsmeldung zeigen
            showingSaveSuccessAlert = true
        } catch {
            print("Fehler beim Speichern der Jahresabrechnung: \(error)")
            // Optional: Fehlermeldung anzeigen
        }
    }
}

// Vorschau-Struktur
struct AnnualBillingInputView_Previews: PreviewProvider {
    static var previews: some View {
        AnnualBillingInputView()
            .environment(\.managedObjectContext, CoreDataStack.preview.context)
    }
}