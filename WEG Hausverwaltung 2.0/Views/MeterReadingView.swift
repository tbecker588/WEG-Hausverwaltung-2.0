import SwiftUI

struct MeterReadingView: View {
    @ObservedObject var heater: Heater
    @State private var currentValue = ""
    
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
        .navigationTitle(heater.identifier)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundGray)
    }
    
    private func saveReading() {
        // Implementiere hier die Core Data-Speicherung
    }
}

struct MeterReadingView_Previews: PreviewProvider {
    static var previews: some View {
        MeterReadingView(heater: Heater.example)
    }
}