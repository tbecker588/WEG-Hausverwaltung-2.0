/**
 * @file    HeatersListView.swift
 * @brief   Listenansicht aller Heizkörper
 * @author  Thomas Becker
 * @date    09.04.2024
 */

import CoreData
import SwiftUI

// MARK: - HeatersListView

/// Hauptansicht zur Verwaltung und Anzeige aller Heizkörper
struct HeatersListView: View {
    // MARK: - Properties

    /// Core Data Kontext für Datenbankoperationen
    @Environment(\.managedObjectContext)
    private var viewContext

    /// Steuert die Anzeige des Dialogs zum Hinzufügen eines Heizkörpers
    @State
    private var showingAddHeater = false

    /// Abfrage aller Heizkörper, sortiert nach Raum
    @FetchRequest(
        entity: WEG_Hausverwaltung_2_0.Heater.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WEG_Hausverwaltung_2_0.Heater.room, ascending: true),
        ]
    )
    private var heaters: FetchedResults<WEG_Hausverwaltung_2_0.Heater>

    // MARK: - Body

    var body: some View {
        List {
            ForEach(heaters) { heater in
                NavigationLink(destination: MeterReadingDetailView(heater: heater)) {
                    HeaterRowView(heater: heater)
                }
            }
            .onDelete(perform: deleteHeaters)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddHeater = true }) {
                    Label("Heizkörper hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Heizkörper")
    }

    // MARK: - Helper Methods

    /// Löscht die ausgewählten Heizkörper aus der Datenbank
    /// - Parameter offsets: Die Indizes der zu löschenden Heizkörper
    private func deleteHeaters(offsets: IndexSet) {
        withAnimation {
            offsets.map { heaters[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - HeaterRowView

/// Einzelne Zeile in der Heizkörperliste
private struct HeaterRowView: View {
    /// Der anzuzeigende Heizkörper
    let heater: WEG_Hausverwaltung_2_0.Heater

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(heater.room ?? "")
                .font(.headline)
                .accessibilityLabel("Raum: \(heater.room ?? "")")

            if let lastReading = heater.lastReading {
                Text("Letzte Ablesung: \(lastReading)")
                    .font(.subheadline)
                    .accessibilityLabel("Letzte Ablesung: \(lastReading)")
            }

            if let owner = heater.owner {
                Text(owner.fullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Eigentümer: \(owner.fullName)")
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}
