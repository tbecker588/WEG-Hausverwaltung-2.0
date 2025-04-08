import Foundation
import SwiftUI

struct MeterReadingDetailView: View {
    @ObservedObject var heater: Heater
    @Environment(\.managedObjectContext) private var context  // NEU: Context via Environment
    @State private var currentValue = ""
    @State private var showSignaturePad = false
    @State private var isReadingSaved = false
    
    // Formattierte Datum-Anzeige
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack {
            // Zähler-Informationsbereich
            VStack(alignment: .leading, spacing: 10) {
                Text("Zähler: \(heater.heaterIdentifier ?? "Unbekannt")")
                    .font(.headline)
                
                HStack {
                    Text("Vorjahreswert:")
                    Text("\(heater.lastReading)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Raum:")
                    Text(heater.room)
                }
            }
            .padding()
            .background(Color.mint.opacity(0.2))
            .cornerRadius(10)
            
            // Numpad-ähnliche Eingabe
            VStack {
                Text("Aktueller Zählerstand")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Zählerstand eingeben", text: $currentValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.title)
            }
            .padding()
            
            // Numpad-Buttons
            NumpadView(value: $currentValue)
            
            // Speichern-Button
            Button(action: {
                if !currentValue.isEmpty {
                    showSignaturePad = true
                }
            }) {
                Text("Speichern")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(currentValue.isEmpty)
            
            // Signatur-Modal
            .sheet(isPresented: $showSignaturePad) {
                SignatureConfirmationView(
                    ownerName: heater.owner?.fullName ?? "Unbekannt", 
                    date: formattedDate,
                    meterReading: currentValue,
                    onConfirm: saveReading
                )
            }
        }
        .navigationTitle("Ablesung \(heater.heaterIdentifier ?? "Unbekannt")")
        .background(DesignSystem.Colors.background)
    }
    
    private func saveReading() {
        // Speichern der Ablesung in CoreData
        let newReading = MeterReading(context: context)  // Verwendet context aus Environment
        newReading.heater = heater
        newReading.previousValue = Double(heater.lastReading) ?? 0
        newReading.currentValue = Double(currentValue) ?? 0
        newReading.date = Date()
        
        do {
            try context.save()  // Verwendet context aus Environment
            isReadingSaved = true
            // Optional: Benachrichtigung oder Navigation
        } catch {
            print("Fehler beim Speichern der Ablesung: \(error)")
        }
    }
}

// Numpad-Komponente für Zählerstandeingabe
struct NumpadView: View {
    @Binding var value: String
    
    let buttons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["0", ",", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { button in
                        Button(action: {
                            handleButtonPress(button)
                        }) {
                            Text(button)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func handleButtonPress(_ button: String) {
        switch button {
        case "⌫":
            // Löschen des letzten Zeichens
            if !value.isEmpty {
                value.removeLast()
            }
        case ",":
            // Einfügen eines Kommas, falls noch kein Komma vorhanden
            if !value.contains(",") {
                value += ","
            }
        default:
            // Maximale Länge und Ziffern-Eingabe begrenzen
            if value.count < 10 {
                value += button
            }
        }
    }
}

// Signatur-Bestätigungsansicht
struct SignatureConfirmationView: View {
    let ownerName: String
    let date: String
    let meterReading: String
    let onConfirm: () -> Void
    
    @State private var signature: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ablesung bestätigen")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Name: \(ownerName)")
                Text("Datum: \(date)")
                Text("Zählerstand: \(meterReading)")
            }
            .padding()
            .background(Color.mint.opacity(0.2))
            .cornerRadius(10)
            
            SignaturePadView { capturedSignature in
                signature = capturedSignature
            }
            .frame(height: 200)
            .border(Color.gray.opacity(0.3), width: 1)
            
            HStack {
                Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(DesignSystem.Colors.error)
                
                Spacer()
                
                Button("Bestätigen") {
                    if signature != nil {
                        onConfirm()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(signature == nil)
                .foregroundColor(DesignSystem.Colors.Button.primary)
            }
            .padding()
        }
        .padding()
        
        if let signature = meterReading.signature,
           let image = UIImage(data: signature) {
            image
        }
    }
}