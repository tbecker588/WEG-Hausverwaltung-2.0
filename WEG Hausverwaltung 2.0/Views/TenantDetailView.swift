import SwiftUI
import CoreData

// MARK: - Mieter Detailansicht
struct TenantDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    // Für die Bearbeitung eines bestehenden Mieters
    var existingTenant: Tenant?
    var associatedOwner: Owner?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var startDate = Date()
    @State private var endDate: Date? = nil
    @State private var hasEndDate = false
    
    // Alert-Status
    @State private var showDataProtectionAlert = false
    @State private var showingSaveSuccessAlert = false
    
    // MARK: - Zusätzliche States
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var isSaving = false
    
    private var isValid: Bool {
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Bitte geben Sie einen Vornamen ein."
            return false
        }
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Bitte geben Sie einen Nachnamen ein."
            return false
        }
        if !email.isEmpty && !email.contains("@") {
            validationMessage = "Bitte geben Sie eine gültige E-Mail-Adresse ein."
            return false
        }
        return true
    }
    
    var body: some View {
        Form {
            Section(header: Text("Persönliche Informationen")) {
                TextField("Vorname", text: $firstName)
                TextField("Nachname", text: $lastName)
                TextField("Telefonnummer", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("E-Mail", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("Mietverhältnis")) {
                DatePicker("Beginn", selection: $startDate, displayedComponents: .date)
                
                Toggle("Befristeter Mietvertrag", isOn: $hasEndDate)
                
                if hasEndDate {
                    DatePicker("Ende", selection: Binding(
                        get: { self.endDate ?? Date() },
                        set: { self.endDate = $0 }
                    ), displayedComponents: .date)
                }
                
                if let existingTenant = existingTenant, let startDate = existingTenant.startDate {
                    Text("Beginn: \(formatDate(startDate))")
                }
                
                if let existingTenant = existingTenant, let endDate = existingTenant.endDate {
                    Text("Ende: \(formatDate(endDate))")
                }
            }
            
            Section {
                Button(action: validateAndSave) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text("Speichern")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .primaryButtonStyle()  // Neuer einheitlicher Style
                .disabled(isSaving)
            }
        }
        .navigationTitle(existingTenant == nil ? "Neuer Mieter" : "Mieter bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadTenantData)
        .alert(isPresented: $showDataProtectionAlert) {
            Alert(
                title: Text("Datenschutzhinweis"),
                message: Text("Die eingegebenen Daten werden ausschließlich zur Verwaltung des Mietverhältnisses verwendet und unterliegen dem Datenschutzgesetz."),
                dismissButton: .default(Text("Verstanden"))
            )
        }
        .alert("Gespeichert", isPresented: $showingSaveSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Die Mieterdaten wurden erfolgreich gespeichert.")
        }
        .alert("Validierungsfehler", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // Lädt Daten eines bestehenden Mieters, falls verfügbar
    private func loadTenantData() {
        // Datenschutzhinweis beim ersten Laden anzeigen
        if existingTenant == nil {
            showDataProtectionAlert = true
        }
        
        if let tenant = existingTenant {
            firstName = tenant.firstName
            lastName = tenant.lastName
            phoneNumber = tenant.phoneNumber ?? ""
            email = tenant.email ?? ""
            
            if let start = tenant.startDate {
                startDate = start
            }
            
            if let end = tenant.endDate {
                endDate = end
                hasEndDate = true
            }
        }
    }
    
    private func validateAndSave() {
        guard isValid else {
            showValidationAlert = true
            return
        }
        
        isSaving = true
        Task {
            await saveTenantAsync()
            isSaving = false
        }
    }
    
    private func saveTenantAsync() async {
        await MainActor.run {
            saveTenant()
        }
    }
    
    private func saveTenant() {
        let tenant: Tenant
        
        // Entweder bestehenden Mieter aktualisieren oder neuen erstellen
        if let existingTenant = existingTenant {
            tenant = existingTenant
        } else {
            tenant = Tenant(context: context)
            tenant.id = UUID()
            
            // Mit Eigentümer verknüpfen, falls vorhanden
            if let owner = associatedOwner {
                tenant.owner = owner
            }
        }
        
        // Daten aktualisieren
        tenant.firstName = firstName
        tenant.lastName = lastName
        tenant.phoneNumber = phoneNumber
        tenant.email = email
        tenant.startDate = startDate
        tenant.endDate = hasEndDate ? endDate : nil
        
        do {
            try context.save()
            showingSaveSuccessAlert = true
        } catch {
            print("Fehler beim Speichern des Mieters: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

// MARK: - Preview-Struktur
struct TenantDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Group {
                // Neuer Mieter
                TenantDetailView()
                    .previewDisplayName("Neuer Mieter")
                
                // Bestehender Mieter
                TenantDetailView(existingTenant: createPreviewTenant())
                    .previewDisplayName("Mieter bearbeiten")
            }
            .environment(\.managedObjectContext, CoreDataStack.preview.context)
        }
    }
    
    private static func createPreviewTenant() -> Tenant {
        let context = CoreDataStack.preview.context
        let tenant = Tenant(context: context)
        tenant.id = UUID()
        tenant.firstName = "Max"
        tenant.lastName = "Mustermann"
        tenant.phoneNumber = "0123456789"
        tenant.email = "max@example.com"
        tenant.startDate = Date()
        return tenant
    }
}
