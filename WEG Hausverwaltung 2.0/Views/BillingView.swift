import Foundation
import CoreData
import SwiftUI

struct BillingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AnnualBilling.year, ascending: false)],
        animation: .default)
    private var billings: FetchedResults<AnnualBilling>
    
    var body: some View {
        List {
            ForEach(billings, id: \.id) { billing in
                NavigationLink {
                    BillingDetailView(billing: billing as NSManagedObject)
                } label: {
                    HStack {
                        Text("Abrechnung \(billing.year)")
                        Spacer()
                        if billing.isFinalized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .onDelete(perform: deleteBillings)
        }
        .navigationTitle("Abrechnungen")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: BillingInputView()) {
                    Image(systemName: "plus")
                }
            }
        }
    }
        
    private func deleteBillings(offsets: IndexSet) {
        withAnimation {
            offsets.map { billings[$0] }.forEach(viewContext.delete)
               
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Fehler beim Löschen: \(nsError)")
            }
        }
    }
}

struct BillingInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var year = Calendar.current.component(.year, from: Date()) - 1
    @State private var waterConsumption: Double = 0
    @State private var waterCost: Double = 0
    @State private var gasConsumption: Double = 0
    @State private var gasCost: Double = 0
    
    var body: some View {
        Form {
            Section(header: Text("Abrechnungsdaten")) {
                Picker("Jahr", selection: $year) {
                    ForEach((Calendar.current.component(.year, from: Date()) - 5)...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Wasserverbrauch (m³)")
                    TextField("z.B. 450", value: $waterConsumption, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
                
                VStack(alignment: .leading) {
                    Text("Wasserkosten (€)")
                    TextField("z.B. 1800", value: $waterCost, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
                       
                VStack(alignment: .leading) {
                    Text("Gasverbrauch (kWh)")
                    TextField("z.B. 18000", value: $gasConsumption, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
                
                VStack(alignment: .leading) {
                    Text("Gaskosten (€)")
                    TextField("z.B. 3600", value: $gasCost, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
            }
            
            Button(action: createBilling) {
                Text("Abrechnung erstellen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Neue Abrechnung")
    }
    
    private func createBilling() {
        withAnimation {
            let annualBilling = AnnualBilling(context: viewContext)
            annualBilling.id = UUID()
            annualBilling.year = Int16(year)
            annualBilling.creationDate = Date()
            annualBilling.totalWaterConsumption = waterConsumption
            annualBilling.totalWaterCost = waterCost
            annualBilling.waterCostPerCubicMeter = waterConsumption > 0 ? waterCost / waterConsumption : 0
            annualBilling.totalGasConsumption = gasConsumption
            annualBilling.totalGasCost = gasCost
            annualBilling.gasCostPerKWh = gasConsumption > 0 ? gasCost / gasConsumption : 0
            annualBilling.totalHeatingConsumption = gasConsumption * 0.92
            annualBilling.warmWaterConsumption = gasConsumption * 0.08
            annualBilling.isFinalized = false
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Fehler beim Erstellen der Abrechnung: \(nsError)")
            }
        }
    }
}