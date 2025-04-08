import SwiftUI
import CoreData

struct HeatersListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Heater.heaterIdentifier, ascending: true)],
        animation: .default)
    private var heaters: FetchedResults<Heater>
    
    @State private var showingAddHeaterSheet = false
    @State private var searchText = ""
    
    var body: some View {
        List {
            ForEach(filteredHeaters, id: \.id) { heater in
                NavigationLink(destination: MeterReadingDetailView(heater: heater)) {
                    HStack(spacing: 15) {
                        Image(systemName: "thermometer")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("\(heater.heaterIdentifier ?? "Unbekannt")")
                                .font(.headline)
                            
                            Text(heater.room)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Letzte Ablesung: \(heater.lastReading)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteHeaters)
        }
        .navigationTitle("Heizkostenverteiler")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddHeaterSheet = true }) {
                    Label("Hinzufügen", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Nach Heizkörper suchen")
        .sheet(isPresented: $showingAddHeaterSheet) {
            AddHeaterView()
        }
    }
    
    private var filteredHeaters: [Heater] {
        if searchText.isEmpty {
            return Array(heaters)
        } else {
            return heaters.filter { heater in
                return (heater.heaterIdentifier?.lowercased().contains(searchText.lowercased()) ?? false) ||
                      heater.room.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private func deleteHeaters(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredHeaters[$0] }.forEach(context.delete)
            
            do {
                try context.save()
            } catch {
                print("Fehler beim Löschen: \(error)")
            }
        }
    }
}

struct AddHeaterView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    @State private var identifier = ""
    @State private var room = ""
    @State private var currentReading = ""
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Owner.lastName, ascending: true)])
    private var owners: FetchedResults<Owner>
    @State private var selectedOwner: Owner?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Heizkostenverteiler")) {
                    TextField("Kennnummer", text: $identifier)
                    TextField("Raum", text: $room)
                    TextField("Aktueller Zählerstand", text: $currentReading)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Zuordnung")) {
                    Picker("Eigentümer", selection: $selectedOwner) {
                        Text("Bitte wählen").tag(nil as Owner?)
                        ForEach(owners) { owner in
                            Text("\(owner.firstName) \(owner.lastName)").tag(owner as Owner?)
                        }
                    }
                }
                
                Button("Speichern") {
                    saveHeater()
                }
                .disabled(identifier.isEmpty || room.isEmpty || selectedOwner == nil)
            }
            .navigationTitle("Neuer Heizkostenverteiler")
            .navigationBarItems(leading: Button("Abbrechen") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveHeater() {
        guard let owner = selectedOwner, !identifier.isEmpty, !room.isEmpty else { return }
        
        let heater = Heater(context: context)
        heater.id = UUID()
        heater.heaterIdentifier = identifier  // Korrektur: konsistente Property-Bezeichnung
        heater.room = room
        heater.lastReading = currentReading.isEmpty ? "0" : currentReading
        heater.owner = owner
        
        do {
            try context.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
}

struct HeatersListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HeatersListView()
                .environment(\.managedObjectContext, CoreDataStack.preview.context)
        }
    }
}