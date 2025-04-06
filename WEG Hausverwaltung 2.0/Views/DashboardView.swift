import SwiftUI

// Definition eines einfachen StatusBadge, falls nicht bereits separat vorhanden.
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - DashboardView
struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Begrüßung in kleinerer Schrift
                    Text("Willkommen im Dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Kachel 1: Daten zur WEG
                    TileView(
                        title: "Daten zur WEG",
                        systemImage: "folder.fill",
                        backgroundColor: .blue
                    )
                    
                    // Kachel 2: Eigentümer/Mieter
                    TileView(
                        title: "Eigentümer/Mieter",
                        systemImage: "person.3.fill",
                        backgroundColor: .green
                    )
                    
                    // Kachel 3: Einnahmen/Ausgaben
                    TileView(
                        title: "Einnahmen/Ausgaben",
                        systemImage: "banknote.fill",
                        backgroundColor: .purple
                    )
                    
                    // Kachel 4: Wohneinheiten
                    TileView(
                        title: "Wohneinheiten",
                        systemImage: "house.fill",
                        backgroundColor: .orange
                    )
                    
                    // Kachel 5: Ablesungen
                    TileView(
                        title: "Ablesungen",
                        systemImage: "gauge.high",
                        backgroundColor: .red
                    )
                    
                     // NavigationLink zur Einstellungen-Ansicht
                    NavigationLink(destination: SettingsView()) {
                        TileView(
                            title: "Einstellungen",
                            systemImage: "gearshape.fill",
                            backgroundColor: .gray
                        )
                    }
                }
                    
                    // Kachel 7: Hilfe
                    TileView(
                        title: "Hilfe",
                        systemImage: "questionmark.circle.fill",
                        backgroundColor: .yellow
                    )
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(Color.passwordsGray)
            .navigationTitle("WEG Hausverwaltung 2.0")
        }
    }

// MARK: - Vorschau
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environment(\.managedObjectContext, CoreDataStack.preview.context)
    }
}

// MARK: - Hilfs-View für eine einzelne Kachel
struct TileView: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)  // Reduzierte Polsterung
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 8) // weniger seitliches Padding
        .padding(.vertical, 10)  // weniger vertikales Padding
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}
