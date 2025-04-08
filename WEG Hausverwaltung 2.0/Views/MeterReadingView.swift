import SwiftUI
import CoreData

struct MeterReadingView: View {
    @ObservedObject var heater: Heater
    @Environment(\.managedObjectContext) private var context
    @State private var currentValue = ""
    @Environment(\.presentationMode) var presentationMode
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: Date())
    }
    
    var body: some View {
        Form {
            Section(
                header: Text(heater.room)
                    .font(.title3),
                footer: Text("Letzte Ablesung: \(heater.lastReading) am \(formattedDate)")
            ) {
                HStack {
                    Text("Aktueller Stand")
                    Spacer()
                    TextField("Zählerwert", text: $currentValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.primaryBlue)
                }
                Button("Mit Foto dokumentieren") {
                    // Hier Kamera-Integration einfügen
                }
                .foregroundColor(Color.primaryBlue)
            }
            
            Section {
                Button("Speichern", action: saveReading)
                    .frame(maxWidth: .infinity)
                    .disabled(currentValue.isEmpty)
            }
            .listRowBackground(Color.secondaryMint.opacity(0.1))
        }
        .navigationTitle(heater.heaterIdentifier ?? "Unbekannt")
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
    }
    
    private func saveReading() {
        guard let value = Double(currentValue) else { return }
        
        let reading = MeterReading(context: context)
        reading.id = UUID()
        reading.date = Date()
        reading.previousValue = Double(heater.lastReading) ?? 0
        reading.currentValue = value
        reading.heater = heater
        
        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}

struct MeterReadingView_Previews: PreviewProvider {
    static var previews: some View {
        MeterReadingView(heater: Heater.example)
    }
}