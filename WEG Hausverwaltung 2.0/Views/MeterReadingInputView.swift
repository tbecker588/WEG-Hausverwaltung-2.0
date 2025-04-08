import SwiftUI

struct MeterReadingInputView: View {
    @State private var readingValue: String = ""
    @State private var showingNumpad = false
    @State private var selectedMeterType: MeterType = .water
    @State private var readingDate = Date()
    
    enum MeterType: String, CaseIterable {
        case water = "Wasser"
        case heating = "Heizung"
        case electricity = "Strom"
        case gas = "Gas"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Zählerstand erfassen")) {
                Picker("Zählertyp", selection: $selectedMeterType) {
                    ForEach(MeterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                DatePicker("Ablesedatum", selection: $readingDate, displayedComponents: .date)
                
                Button(action: {
                    showingNumpad = true
                }) {
                    HStack {
                        Text("Zählerstand eingeben")
                        Spacer()
                        Text(readingValue.isEmpty ? "Nicht erfasst" : readingValue)
                            .foregroundColor(readingValue.isEmpty ? .secondary : .primary)
                    }
                }
            }
            
            if !readingValue.isEmpty {
                Section {
                    Button("Speichern") {
                        saveReading()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Zählerstand erfassen")
        .sheet(isPresented: $showingNumpad) {
            VStack {
                HStack {
                    Text("Zählerstand für \(selectedMeterType.rawValue)")
                        .font(.headline)
                    Spacer()
                    Button("Abbrechen") {
                        showingNumpad = false
                    }
                }
                .padding()
                
                Divider()
                
                UniversalNumpad(value: $readingValue) {
                    showingNumpad = false
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(15)
            .padding()
        }
    }
    
    private func saveReading() {
        // Hier würden wir den Zählerstand in der Datenbank speichern
        // Beispiel:
        print("Zählerstand gespeichert: \(selectedMeterType.rawValue) = \(readingValue) am \(readingDate)")
        
        // Zurücksetzen der Eingabe
        readingValue = ""
    }
}

struct MeterReadingInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MeterReadingInputView()
        }
    }
}