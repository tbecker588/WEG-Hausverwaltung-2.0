import CoreData
import SwiftUI

struct OwnerListView: View {
    @Environment(\.managedObjectContext)
    private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Owner.lastName, ascending: true)],
        animation: .default
    )
    private var owners: FetchedResults<Owner>

    @State
    private var showingAddOwnerView = false
    @State
    private var searchText = ""

    // Neue States für den Eigentümerwechsel
    @State
    private var showingOwnerTransferSheet = false
    @State
    private var selectedOwnerForTransfer: Owner?
    @State
    private var transferReason = ""
    @State
    private var transferDate = Date()

    // State für Alerts
    @State
    private var showingAlert = false
    @State
    private var alertTitle = ""
    @State
    private var alertMessage = ""

    var body: some View {
        List {
            ForEach(filteredOwners) { owner in
                NavigationLink(destination: OwnerDetailView(existingOwner: owner)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(owner.firstName) \(owner.lastName)")
                                .font(.headline)

                            if owner.isRented {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }

                        Text("Wohnung \(owner.apartmentNumber ?? ""), \(String(format: "%.1f", owner.ownershipShare))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: initiateTransfer)
        }
        .navigationTitle("Eigentümer")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddOwnerView = true }) {
                    Label("Hinzufügen", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Eigentümer suchen")
        .sheet(isPresented: $showingAddOwnerView) {
            NavigationStack {
                OwnerDetailView()
                    .environment(\.managedObjectContext, context)
                    .navigationBarItems(leading: Button("Abbrechen") {
                        showingAddOwnerView = false
                    })
            }
        }
        .sheet(isPresented: $showingOwnerTransferSheet) {
            ownerTransferSheet
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // Gefilterte Liste basierend auf der Suchtext-Eingabe
    private var filteredOwners: [Owner] {
        if searchText.isEmpty {
            Array(owners)
        } else {
            owners.filter { owner in
                let fullName = "\(owner.firstName) \(owner.lastName)".lowercased()
                return fullName.contains(searchText.lowercased()) ||
                    (owner.apartmentNumber ?? "").lowercased().contains(searchText.lowercased())
            }
        }
    }

    // Umbenennung von deleteOwners zu initiateTransfer
    private func initiateTransfer(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let owner = filteredOwners[index]
                initiateOwnerTransfer(owner: owner)
            }
        }
    }

    // Funktion für den Eigentümerwechsel
    private func initiateOwnerTransfer(owner: Owner) {
        selectedOwnerForTransfer = owner
        showingOwnerTransferSheet = true
    }

    // Sheet für den Eigentümerwechsel
    var ownerTransferSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Grund des Eigentümerwechsels")) {
                    Picker("Grund", selection: $transferReason) {
                        Text("Verkauf").tag("Verkauf")
                        Text("Tod").tag("Tod")
                    }
                    DatePicker("Datum", selection: $transferDate, displayedComponents: .date)
                }

                Section(header: Text("Wichtige Hinweise")) {
                    Text("1. Erst neuen Eigentümer anlegen")
                    Text("2. Zwischenabrechnung erstellen")
                    Text("3. Daten übertragen")
                    Text("4. Alte Daten archivieren")
                }

                Button("Eigentümerwechsel starten") {
                    startOwnerTransfer()
                }
                .disabled(transferReason.isEmpty)
            }
            .navigationTitle("Eigentümerwechsel")
        }
    }

    // Erweiterung des Transfer-Prozesses
    private func startOwnerTransfer() {
        guard let oldOwner = selectedOwnerForTransfer else { return }

        // 1. Prüfe ob Zwischenabrechnung möglich
        guard canCreateIntermediateSettlement(for: oldOwner) else {
            showAlert(
                title: "Fehler",
                message: "Zwischenabrechnung nicht möglich - Bitte erst Zählerstände erfassen"
            )
            return
        }

        // 2. Prüfe ob neuer Eigentümer vorhanden
        guard let newOwner = findNewOwner() else {
            showAlert(
                title: "Hinweis",
                message: "Bitte zuerst neuen Eigentümer anlegen"
            )
            return
        }

        let transferService = OwnerTransferService(context: context)
        transferService.transferOwnership(
            from: oldOwner,
            to: newOwner,
            reason: transferReason,
            date: transferDate
        ) { result in
            switch result {
            case .success:
                showingOwnerTransferSheet = false
                showAlert(
                    title: "Erfolg",
                    message: "Eigentümerwechsel erfolgreich durchgeführt"
                )
            case let .failure(error):
                showAlert(
                    title: "Fehler",
                    message: "Fehler beim Eigentümerwechsel: \(error.localizedDescription)"
                )
            }
        }
    }

    // Hilfsfunktionen
    private func canCreateIntermediateSettlement(for owner: Owner) -> Bool {
        // Prüfe ob alle notwendigen Daten für Zwischenabrechnung vorliegen
        guard let heaters = owner.heaters as? Set<Heater> else { return false }

        // Prüfe ob aktuelle Zählerstände vorhanden
        return heaters.allSatisfy { heater in
            guard let readings = heater.meterReadings as? Set<MeterReading> else { return false }
            return !readings.isEmpty
        }
    }

    private func findNewOwner() -> Owner? {
        // Implementierung der Suche nach dem neuen Eigentümer
        nil
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct OwnerListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OwnerListView()
                .environment(\.managedObjectContext, CoreDataStack.preview.context)
        }
    }
}
