import SwiftUI
import CoreData

// MARK: - Eigentümer Detailansicht
struct OwnerDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    // Für die Bearbeitung eines bestehenden Eigentümers
    var existingOwner: Owner?
    
    // Persönliche Informationen
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    
    // Wohnungsinformationen
    @State private var apartmentNumber = ""
    @State private var floorNumber = ""
    @State private var ownershipShare: Double = 100.0
    
    // Kontaktinformationen
    @State private var iban = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    
    // Bewohnerstatus
    @State private var isRented = false
    @State private var occupantCount = 1
    
    // Zusätzliche Informationen
    @State private var garageNumber = ""
    @State private var basementNumber = ""
    
    // Alert-Status
    @State private var showingSaveSuccessAlert = false
    
    var body: some View {
        Form {
            // Persönliche Informationen
            Section(header: Text("Persönliche Informationen")) {
                TextField("Vorname", text: $firstName)
                TextField("Nachname", text: $lastName)
                TextField("E-Mail", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                TextField("Telefonnummer", text: $phoneNumber)
                    .keyboardType(.phonePad)
            }
            
            // Wohnungsinformationen
            Section(header: Text("Wohnungsinformationen")) {
                TextField("Wohnungsnummer", text: $apartmentNumber)
                TextField("Etage", text: $floorNumber)
                
                HStack {
                    Text("Eigentumsanteil (%)")
                    Spacer()
                    TextField("Anteil %", value: $ownershipShare, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            
            // Bewohnerstatus
            Section(header: Text("Bewohnerstatus")) {
                Toggle("Vermietet", isOn: $isRented)
                
                if !isRented {
                    Stepper("Anzahl Personen: \(occupantCount)", 
                            value: $occupantCount, 
                            in: 1...10)
                } else {
                    NavigationLink(destination: TenantDetailView()) {
                        Text("Mieter verwalten")
                    }
                }
            }
            
            // Zusätzliche Informationen
            Section(header: Text("Zusätzliche Informationen")) {
                TextField("Garage Nr.", text: $garageNumber)
                TextField("Keller Nr.", text: $basementNumber)
            }
            
            // Kontaktinformationen
            Section(header: Text("Bankverbindung")) {
                TextField("IBAN", text: $iban)
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            // Notfallkontakt
            Section(header: Text("Notfallkontakt")) {
                TextField("Name", text: $emergencyContactName)
                TextField("Telefon", text: $emergencyContactPhone)
                    .keyboardType(.phonePad)
            }
            
            // Speichern-Button
            Section {
                Button(action: saveOwner) {
                    Text("Speichern")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .navigationTitle(existingOwner == nil ? "Neuer Eigentümer" : "Eigentümer bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadOwnerData)
        .alert(isPresented: $showingSaveSuccessAlert) {
            Alert(
                title: Text("Gespeichert"),
                message: Text("Der Eigentümer wurde erfolgreich gespeichert."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // Lädt Daten eines bestehenden Eigentümers, falls verfügbar
    private func loadOwnerData() {
        if let owner = existingOwner {
            firstName = owner.firstName
            lastName = owner.lastName
            email = owner.email ?? ""
            phoneNumber = owner.phoneNumber ?? ""
            apartmentNumber = owner.apartmentNumber ?? ""
            floorNumber = owner.floorNumber ?? ""
            ownershipShare = owner.ownershipShare
            iban = owner.iban ?? ""
            emergencyContactName = owner.emergencyContactName ?? ""
            emergencyContactPhone = owner.emergencyContactPhone ?? ""
            isRented = owner.isRented
            occupantCount = Int(owner.occupantCount)
            garageNumber = owner.garageNumber ?? ""
            basementNumber = owner.basementNumber ?? ""
        }
    }
    
    private func saveOwner() {
        let owner: Owner
        
        // Entweder bestehenden Eigentümer aktualisieren oder neuen erstellen
        if let existingOwner = existingOwner {
            owner = existingOwner
        } else {
            owner = Owner(context: context)
            owner.id = UUID()
        }
        
        // Daten aktualisieren
        owner.firstName = firstName
        owner.lastName = lastName
        owner.email = email
        owner.phoneNumber = phoneNumber
        owner.apartmentNumber = apartmentNumber
        owner.floorNumber = floorNumber
        owner.ownershipShare = ownershipShare
        owner.iban = iban
        owner.emergencyContactName = emergencyContactName
        owner.emergencyContactPhone = emergencyContactPhone
        owner.isRented = isRented
        owner.occupantCount = Int16(occupantCount)
        owner.garageNumber = garageNumber
        owner.basementNumber = basementNumber
        
        do {
            try context.save()
            showingSaveSuccessAlert = true
        } catch {
            print("Fehler beim Speichern des Eigentümers: \(error)")
        }
    }
}

// MARK: - Preview-Struktur
struct OwnerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            // Bearbeiten eines existierenden Eigentümers
            let context = CoreDataStack.preview.context
            let owner = Owner(context: context)
            owner.id = UUID()
            owner.firstName = "Max"
            owner.lastName = "Mustermann"
            owner.apartmentNumber = "A101"
            owner.ownershipShare = 16.67
            
            OwnerDetailView(existingOwner: owner)
                .environment(\.managedObjectContext, context)
        }
    }
}