//
//  Hausverwaltung_2_0App.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct Hausverwaltung_2_0App: App {
    private let sharedModelContainer: ModelContainer
    private let startfehler: String?

    init() {
        let schema = Schema([
            Item.self,
            AbrechnungsJahr.self,
            WEG.self,
            Wohnung.self,
            HeizkostenverteilerZaehler.self,
            Wasserzaehler.self,
            Kostenart.self,
            AuslagenEintrag.self,
            AusgabenItem.self,
            ZahlungsItem.self,
            AbrechnungsErgebnis.self,
            AdminEinstellungen.self,
            AenderungsLog.self,
            HKVHistorieEintrag.self,
            WasserzaehlerHistorieEintrag.self,
            EigentuemerProfil.self,
            AbrechnungsZeileKonfiguration.self,
        ])

        // Versuche zuerst normalen Container (behält alle Daten).
        // CloudKit-Sync ist hier bewusst deaktiviert, da die App Backups über
        // Dateien/iCloud Drive/PocketBase nutzt und das Datenmodell nicht als
        // CloudKit-SwiftData-Schema modelliert ist.
        let normalConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [normalConfig]) {
            self.sharedModelContainer = container
            self.startfehler = nil
            return
        }

        // Kein automatisches Löschen des Stores: Daten dürfen nicht still verloren gehen.
        // Statt Absturz startet die App im Recovery-Modus mit In-Memory-Container.
        let fallbackConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        guard let fallbackContainer = try? ModelContainer(for: schema, configurations: [fallbackConfig]) else {
            fatalError("ModelContainer konnte nicht erstellt werden (weder persistent noch In-Memory).")
        }
        self.sharedModelContainer = fallbackContainer
        self.startfehler = "Die lokale Datenbank konnte nicht geladen werden (Migration fehlgeschlagen)."
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let startfehler {
                    StartupRecoveryView(fehlerText: startfehler)
                } else {
                    AbrechnungMainTabView()
                }
            }
                .environment(\.locale, Locale(identifier: "de_DE"))
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct StartupRecoveryView: View {
    let fehlerText: String

    @State private var statusText = ""
    @State private var zeigeResetDialog = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Datenbank-Recovery")
                    .font(.title2.bold())

                Text(fehlerText)
                    .foregroundStyle(.red)

                Text("Die App wurde im sicheren Recovery-Modus gestartet, damit keine Daten automatisch gelöscht werden.")

                Text("Empfohlenes Vorgehen:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Falls vorhanden: aktuelles JSON-Backup bereithalten (Dateien/iCloud/PocketBase).")
                    Text("2. Unten die Store-Dateien manuell zurücksetzen.")
                    Text("3. App neu starten und Backup über Einstellungen wiederherstellen.")
                }
                .font(.subheadline)

                Button("Store-Dateien manuell zurücksetzen", role: .destructive) {
                    zeigeResetDialog = true
                }
                .buttonStyle(.borderedProminent)

                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Sicherer Start")
        }
        .confirmationDialog(
            "Store-Dateien wirklich löschen?",
            isPresented: $zeigeResetDialog,
            titleVisibility: .visible
        ) {
            Button("Ja, löschen", role: .destructive) {
                do {
                    let geloeschteDateien = try StoreRecovery.loeschePersistenteStoreDateien()
                    statusText = "Bereinigt: \(geloeschteDateien) Datei(en). Bitte App jetzt vollständig schließen und neu öffnen."
                } catch {
                    statusText = "Reset fehlgeschlagen: \(error.localizedDescription)"
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieser Schritt löscht nur die lokale Datenbank im App-Sandbox-Verzeichnis. Backups bleiben erhalten.")
        }
    }
}

private enum StoreRecovery {
    static func loeschePersistenteStoreDateien() throws -> Int {
        let fm = FileManager.default
        let supportURL = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        var suchpfade = [supportURL]
        if let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty {
            suchpfade.append(supportURL.appendingPathComponent(bundleID, isDirectory: true))
        }

        var dateienZumLoeschen = [URL]()
        for pfad in suchpfade {
            guard fm.fileExists(atPath: pfad.path) else { continue }
            let inhalte = try fm.contentsOfDirectory(at: pfad, includingPropertiesForKeys: nil)
            for url in inhalte {
                let name = url.lastPathComponent.lowercased()
                if name.contains(".store") ||
                    name.hasSuffix(".sqlite") ||
                    name.hasSuffix(".sqlite-wal") ||
                    name.hasSuffix(".sqlite-shm") {
                    dateienZumLoeschen.append(url)
                }
            }
        }

        let uniqueDateien = Array(Set(dateienZumLoeschen))
        guard !uniqueDateien.isEmpty else {
            throw NSError(
                domain: "StoreRecovery",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Keine Store-Dateien gefunden."]
            )
        }

        for url in uniqueDateien {
            try fm.removeItem(at: url)
        }
        return uniqueDateien.count
    }
}
