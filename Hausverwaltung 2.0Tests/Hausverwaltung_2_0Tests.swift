//
//  Hausverwaltung_2_0Tests.swift
//  Hausverwaltung 2.0Tests
//
//  Created by Thomas Becker on 17.04.26.
//

import Testing
import SwiftData
@testable import Hausverwaltung_2_0

struct Hausverwaltung_2_0Tests {

    @MainActor
    @Test func backupRestoreErhaeltAusgabenUndKategorien() throws {
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

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let weg = WEG(name: "Test WEG", adresse: "Teststr. 1", abrechnungsjahr: 2026)
        weg.ausgabenKategorienRaw = "Wasser|Sonderumlage"

        let jan = AusgabenItem(kategorie: "Wasser", monat: 1, betrag: 120.50, weg: weg)
        let feb = AusgabenItem(kategorie: "Wasser", monat: 2, betrag: 118.75, weg: weg)
        let korr = AusgabenItem(kategorie: "Sonderumlage", monat: 13, betrag: -25.00, weg: weg)

        weg.ausgaben.append(contentsOf: [jan, feb, korr])
        context.insert(weg)
        context.insert(jan)
        context.insert(feb)
        context.insert(korr)
        try context.save()

        let manager = BackupManager()
        let url = try manager.exportBackup(
            weg: weg,
            eigentuemerProfile: [],
            abrechnungsZeilen: [],
            aenderungsLog: [],
            adminPinHash: nil
        )

        let geladen = try manager.ladeBackup(von: url)
        #expect(geladen.weg?.ausgaben?.count == 3)

        try manager.wiederherstellenBackup(geladen, modelContext: context)

        let wegs = try context.fetch(FetchDescriptor<WEG>())
        #expect(wegs.count == 1)
        guard let restored = wegs.first else {
            Issue.record("Keine WEG nach Restore gefunden")
            return
        }

        #expect(restored.ausgaben.count == 3)
        #expect(restored.ausgaben.contains { $0.kategorie == "Sonderumlage" && $0.monat == 13 && $0.betrag == -25.00 })
        #expect(restored.ausgabenKategorienRaw.contains("Sonderumlage"))
    }

}
