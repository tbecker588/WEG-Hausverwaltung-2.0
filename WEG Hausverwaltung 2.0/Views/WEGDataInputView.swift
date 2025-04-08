import SwiftUI
import CoreData

struct WEGDataInputView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    // Basis-WEG-Daten
    @State private var name = ""
    @State private var street = ""
    @State private var houseNumber = ""
    @State private var postalCode = ""
    @State private var city = ""
    
    // Verwaltungsdaten
    @State private var administrator = ""
    @State private var contact = ""
    @State private var email = ""
    @State private var phone = ""
    
    // Gebäudedaten
    @State private var constructionYear = ""
    @State private var apartmentCount = ""
    @State private var totalArea = ""
    
    // Status
    @State private var showSaveAlert = false
    
    // MARK: - States für Validierung und Loading
    @State private var validationErrors: [String] = []
    @State private var showValidationAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Validierung
    private var isValid: Bool {
        validationErrors.removeAll()
        
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Name der WEG ist erforderlich")
        }
        if street.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Straße ist erforderlich")
        }
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors.append("Stadt ist erforderlich")
        }
        if !email.isEmpty && !email.contains("@") {
            validationErrors.append("E-Mail-Adresse ist ungültig")
        }
        
        return validationErrors.isEmpty
    }
    
    var body: some View {
        Form {
            // Basis-WEG-Daten
            Section(header: Text("Allgemeine Angaben")) {
                TextField("Name der WEG", text: $name)
                TextField("Straße", text: $street)
                TextField("Hausnummer", text: $houseNumber)
                    .keyboardType(.numbersAndPunctuation)
                TextField("PLZ", text: $postalCode)
                    .keyboardType(.numberPad)
                TextField("Ort", text: $city)
            }
            
            // Verwaltungsdaten
            Section(header: Text("Verwaltung")) {
                TextField("Verwaltername", text: $administrator)
                TextField("Ansprechpartner", text: $contact)
                TextField("E-Mail", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                TextField("Telefon", text: $phone)
                    .keyboardType(.phonePad)
            }
            
            // Gebäudedaten
            Section(header: Text("Gebäudedaten")) {
                TextField("Baujahr", text: $constructionYear)
                    .keyboardType(.numberPad)
                TextField("Anzahl Wohnungen", text: $apartmentCount)
                    .keyboardType(.numberPad)
                TextField("Gesamtfläche (m²)", text: $totalArea)
                    .keyboardType(.decimalPad)
            }
            
            // Speichern-Button
            Section {
                Button(action: validateAndSave) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Speichern")
                    }
                }
                .frame(maxWidth: .infinity)
                .primaryButtonStyle()  // Neuer einheitlicher Style
                .disabled(!isValid || isLoading)
            }
            .listRowBackground(DesignSystem.Colors.List.rowBackground)
        }
        .navigationTitle("WEG Daten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadWEGData)
        .alert("Validierungsfehler", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
        .alert("Erfolg", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Die WEG-Daten wurden erfolgreich gespeichert.")
        }
    }
    
    private func loadWEGData() {
        // Laden der bestehenden WEG-Daten
        let request = NSFetchRequest<WEG>(entityName: "WEG")
        
        do {
            let results = try context.fetch(request)
            if let weg = results.first {
                name = weg.name
                street = weg.street ?? ""
                houseNumber = weg.houseNumber ?? ""
                postalCode = weg.postalCode ?? ""
                city = weg.city ?? ""
                administrator = weg.administrator ?? ""
                contact = weg.contact ?? ""
                email = weg.email ?? ""
                phone = weg.phone ?? ""
                constructionYear = weg.constructionYear > 0 ? "\(weg.constructionYear)" : ""
                apartmentCount = weg.apartmentCount > 0 ? "\(weg.apartmentCount)" : ""
                totalArea = weg.totalArea > 0 ? "\(weg.totalArea)" : ""
            }
        } catch {
            print("Fehler beim Laden der WEG-Daten: \(error)")
        }
    }
    
    private func validateAndSave() {
        guard isValid else {
            showValidationAlert = true
            return
        }
        
        isLoading = true
        Task {
            await saveWEGDataAsync()
            isLoading = false
        }
    }
    
    private func saveWEGDataAsync() async {
        await MainActor.run {
            saveWEGData()
        }
    }
    
    private func saveWEGData() {
        // Bestehende WEG-Daten suchen oder neu erstellen
        let request = NSFetchRequest<WEG>(entityName: "WEG")
        
        do {
            let results = try context.fetch(request)
            let weg: WEG
            
            if let existingWEG = results.first {
                weg = existingWEG
            } else {
                weg = WEG(context: context)
                weg.id = UUID()
            }
            
            // Daten aktualisieren
            weg.name = name
            weg.street = street
            weg.houseNumber = houseNumber
            weg.postalCode = postalCode
            weg.city = city
            weg.administrator = administrator
            weg.contact = contact
            weg.email = email
            weg.phone = phone
            weg.constructionYear = Int16(constructionYear) ?? 0
            weg.apartmentCount = Int16(apartmentCount) ?? 0
            weg.totalArea = Double(totalArea.replacingOccurrences(of: ",", with: ".")) ?? 0
            
            try context.save()
            showSaveAlert = true
            
        } catch {
            print("Fehler beim Speichern der WEG-Daten: \(error)")
        }
    }
}

struct WEGDataInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Group {
                // Leeres Formular
                WEGDataInputView()
                    .previewDisplayName("Neue WEG")
                
                // Vorausgefülltes Formular
                WEGDataInputView()
                    .environment(\.managedObjectContext, createPreviewContext())
                    .previewDisplayName("Bestehende WEG")
            }
        }
    }
    
    private static func createPreviewContext() -> NSManagedObjectContext {
        let context = CoreDataStack.preview.context
        let weg = WEG(context: context)
        weg.id = UUID()
        weg.name = "Muster WEG"
        weg.street = "Musterstraße"
        weg.houseNumber = "1"
        weg.postalCode = "12345"
        weg.city = "Musterstadt"
        weg.administrator = "Max Mustermann"
        weg.constructionYear = 1980
        weg.apartmentCount = 12
        weg.totalArea = 1200.0
        return context
    }
}