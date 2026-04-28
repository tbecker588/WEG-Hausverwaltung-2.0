//
//  BackupManager.swift
//  Hausverwaltung 2.0
//
//  JSON-basierter Backup/Restore-Service für alle WEG-Daten.
//  Kein SwiftData-Migrations-Overhead: einfaches Serialisieren aller Modelle in
//  portable Structs (DTOs) und Schreiben als .hausverwaltung-Datei.
//

import Foundation
import SwiftData

// MARK: - Backup-Datei-Struktur

struct HausverwaltungBackup: Codable {
    let version: Int                              // Formatversion für spätere Migrationen
    let erstelltAm: Date
    let weg: WEGBackup?
    let wegs: [WEGBackup]?
    let eigentuemerProfile: [EigentuemerProfilBackup]
    let abrechnungsZeilen: [AbrechnungsZeileBackup]
    let aenderungsLog: [AenderungsLogBackup]
    let adminPinHash: String?

    enum CodingKeys: String, CodingKey {
        case version
        case erstelltAm
        case weg
        case wegs
        case eigentuemerProfile
        case abrechnungsZeilen
        case aenderungsLog
        case adminPinHash
    }

    init(
        version: Int,
        erstelltAm: Date,
        weg: WEGBackup?,
        wegs: [WEGBackup]?,
        eigentuemerProfile: [EigentuemerProfilBackup],
        abrechnungsZeilen: [AbrechnungsZeileBackup],
        aenderungsLog: [AenderungsLogBackup],
        adminPinHash: String?
    ) {
        self.version = version
        self.erstelltAm = erstelltAm
        self.weg = weg
        self.wegs = wegs
        self.eigentuemerProfile = eigentuemerProfile
        self.abrechnungsZeilen = abrechnungsZeilen
        self.aenderungsLog = aenderungsLog
        self.adminPinHash = adminPinHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.erstelltAm = try container.decodeIfPresent(Date.self, forKey: .erstelltAm) ?? Date()
        self.weg = try container.decodeIfPresent(WEGBackup.self, forKey: .weg)
        self.wegs = try container.decodeIfPresent([WEGBackup].self, forKey: .wegs)
        self.eigentuemerProfile = try container.decodeIfPresent([EigentuemerProfilBackup].self, forKey: .eigentuemerProfile) ?? []
        self.abrechnungsZeilen = try container.decodeIfPresent([AbrechnungsZeileBackup].self, forKey: .abrechnungsZeilen) ?? []
        self.aenderungsLog = try container.decodeIfPresent([AenderungsLogBackup].self, forKey: .aenderungsLog) ?? []
        self.adminPinHash = try container.decodeIfPresent(String.self, forKey: .adminPinHash)
    }
}

// MARK: - DTO: WEG

struct WEGBackup: Codable {
    let id: UUID
    let name: String
    let adresse: String
    let abrechnungsjahr: Int
    let abgeschlossen: Bool
    let abgeschlossenAm: Date?
    let istMusterjahr: Bool?

    // Messwerte
    let brennstoffverbrauchKwh: Double
    let faktorProKwhEuro: Double
    let verbrauchHeizungKwh: Double
    let verbrauchWarmwasserKwh: Double
    let gesamtwasserbetragLtRechnungEuro: Double
    let niederschlagswasserEuro: Double

    // Fixkosten
    let verguetungHmtEuro: Double
    let heizungWartungRepEuro: Double
    let schornsteinfegerEuro: Double
    let wartungBaurEuro: Double
    let allgemeinStromEuro: Double
    let muellGebuehrenEuro: Double
    let muellGesamtPersonen: Int
    let versicherungGebaeudeMitFeuerEuro: Double
    let versicherungHausHaftpflichtEuro: Double
    let hausUndGrundEuro: Double
    let nebenkostenGeldverkehrEuro: Double
    let reparaturenAnschaffungenEuro: Double
    let ruecklagenEuro: Double
    let kontoAktuellEuro: Double

    // Hauptzähler
    let hauptwasserZaehlerAnfang: Double
    let hauptwasserZaehlerEnde: Double

    // Header
    let abrechnungsHeaderTitel: String
    let abrechnungsHeaderUntertitel: String
    let abrechnungsHeaderPunkteText: String
    let standardVerteilungsschluesselRaw: String
    let ausgabenKategorienRaw: String?

    // WEG-Verwaltung
    let hausverwalterName: String?
    let hausverwalterStrasse: String?
    let hausverwalterPlz: String?
    let hausverwalterOrt: String?
    let hausverwalterTelefon: String?
    let hausverwalterEmail: String?
    let hausverwalterArtRaw: String?
    let hausverwalterGewaehltAm: Date?
    let abrechnungszeitraumVon: Date?
    let abrechnungszeitraumBis: Date?
    let wegLogoBildData: Data?
    let pdfSchriftGroesseRaw: String?
    let pdfRandBreiteRaw: String?
    let pdfHeaderFarbeRaw: String?
    let pdfFusszeileEinblenden: Bool?
    let pdfLogoPositionRaw: String?
    let pdfLogoHoehePt: Double?
    let pdfLogoSkalierung: Double?
    let pdfLogoOffsetY: Double?
    let pdfTitelAbstandOben: Double?
    let pdfTabellenStartOffsetY: Double?
    let pdfKopfzeileText: String?
    let pdfKopfzeileOffsetY: Double?
    let pdfAdresseOffsetX: Double?
    let pdfAdresseOffsetY: Double?
    let pdfFusszeile1Text: String?
    let pdfFusszeile2Text: String?
    let pdfFusszeile1OffsetY: Double?
    let pdfFusszeile2OffsetY: Double?

    // Wohnungen
    let wohnungen: [WohnungBackup]

    // Ausgaben (Monatswerte inkl. Korrekturzeilen)
    let ausgaben: [AusgabenItemBackup]?
    // Detaillierte Auslagenliste
    let auslagenEintraege: [AuslagenEintragBackup]?
}

// MARK: - DTO: Wohnung

struct WohnungBackup: Codable {
    let id: UUID
    let eigentuemer: String
    let wohnungsnummer: Int
    let flaeche_qm: Double
    let personenanzahl: Int
    let eigentumsanteilTausendstel: Int
    let email: String?

    let heizPunkteAnfang: Double
    let heizPunkteEnde: Double
    let wasserWohnungZaehlerAnfang: Double
    let wasserWohnungZaehlerEnde: Double
    let wasserWaschkuecheZaehlerAnfang: Double
    let wasserWaschkuecheZaehlerEnde: Double

    let heizkostenverteiler: [HKVBackup]
    let wasserzaehler: [WasserzaehlerBackup]
    let zahlungen: [ZahlungsItemBackup]
    let abrechnungsErgebnis: AbrechnungsErgebnisBackup?
}

// MARK: - DTO: Auslagen

struct AuslagenEintragBackup: Codable {
    let id: UUID
    let monat: Int
    let betrag: Double
    let verwendungszweck: String
    let kaufort: String
    let datum: Date
}

// MARK: - DTO: HKV

struct HKVBackup: Codable {
    let id: UUID
    let nummer: String
    let bezeichnung: String
    let heizungstyp: String
    let hinweis: String
    let datum: String
    let faktor: Double
    let ablesewertNeu: Double
    let verbrauchPunkte: Double
}

// MARK: - DTO: Wasserzähler

struct WasserzaehlerBackup: Codable {
    let id: UUID
    let nummer: String
    let art: String
    let bezeichnung: String
    let typ: String
    let datum: String
    let ablesewertAlt: Double
    let ablesewertNeu: Double
    let faktor: Double
}

// MARK: - DTO: Zahlungen

struct ZahlungsItemBackup: Codable {
    let id: UUID
    let kostenart: String
    let betrag: Double
    let monat: Int
}

// MARK: - DTO: Ausgaben

struct AusgabenItemBackup: Codable {
    let id: UUID
    let kategorie: String
    let monat: Int
    let betrag: Double
}

// MARK: - DTO: Abrechnungsergebnis

struct AbrechnungsErgebnisBackup: Codable {
    let id: UUID
    let heizungAnteil30Prozent: Double
    let heizungAnteil70Prozent: Double
    let heizungGesamt: Double
    let wasserAnteil30Prozent: Double
    let wasserAnteil70Prozent: Double
    let wasserGesamt: Double
    let kaltwasserGesamt: Double
    let sonstigeKosten: Double
    let zahlungsabweichung: Double
    let berechnungsDatum: Date
}

// MARK: - DTO: Eigentümer-Profil

struct EigentuemerProfilBackup: Codable {
    let id: UUID
    let abrechnungsjahr: Int
    let vorname: String
    let nachname: String
    let strasse: String
    let plz: String
    let ort: String
    let wohnungsnummer: Int?
    let eigentumsanteilTausendstel: Int
    let nutzungsart: String
    let mieterName: String
    let haushaltPersonen: Int
    let geburtsdatum: Date?
    let notfallkontakt: String
    let notfallkontaktTelefon: String
    let telefon: String
    let email: String
}

// MARK: - DTO: Abrechnungszeile

struct AbrechnungsZeileBackup: Codable {
    let id: UUID
    let abrechnungsjahr: Int
    let name: String
    let gesamtbetragEuro: Double
    let schluesselArt: String
    let istGlobal: Bool
    let wohnungsnummer: Int?
    let gesamtSchluesselManuell: Double
    let wohnungsSchluesselManuell: Double
    let sortierung: Int
    let aktiv: Bool
    let systemCode: String
    let istStandard: Bool
    let betragQuellenRaw: String
    let schluesselGesamtQuelleRaw: String
    let schluesselWertQuelleRaw: String
    let wohnungsBetragQuelleRaw: String
    let schluesselBezeichnungOverride: String
    let anteilsModellRaw: String
    let wohnungsSchluesselManuellMapRaw: String?
}

// MARK: - DTO: Änderungslog

struct AenderungsLogBackup: Codable {
    let id: UUID
    let datum: Date
    let bereich: String
    let wohnungsnummer: Int
    let eigentuemer: String
    let zaehlernummer: String
    let feldname: String
    let altWert: String
    let neuWert: String
    let grund: String
}

// MARK: - BackupManager

class BackupManager {
    enum BackupError: LocalizedError {
        case keineDaten
        case ungueltigeDatei(String)
        case encodingFehler(Error)
        case decodingFehler(Error)
        case speichernFehler(Error)
        case lesenFehler(Error)

        var errorDescription: String? {
            switch self {
            case .keineDaten: return "Keine WEG-Daten gefunden."
            case .ungueltigeDatei(let details): return "Datei ungültig: \(details)"
            case .encodingFehler(let e): return "Fehler beim Erstellen: \(e.localizedDescription)"
            case .decodingFehler(let e): return "Datei ungültig: \(e.localizedDescription)"
            case .speichernFehler(let e): return "Speichern fehlgeschlagen: \(e.localizedDescription)"
            case .lesenFehler(let e): return "Lesen fehlgeschlagen: \(e.localizedDescription)"
            }
        }
    }

    // MARK: - Export

    /// Erstellt ein Backup aller WEG-Daten und gibt die Datei-URL zurück.
    func exportBackup(
        wegs: [WEG],
        eigentuemerProfile: [EigentuemerProfil],
        abrechnungsZeilen: [AbrechnungsZeileKonfiguration],
        aenderungsLog: [AenderungsLog],
        adminPinHash: String?
    ) throws -> URL {
        guard !wegs.isEmpty else { throw BackupError.keineDaten }

        let sortierteWegs = wegs.sorted { $0.abrechnungsjahr > $1.abrechnungsjahr }
        guard let neuestesWeg = sortierteWegs.first else { throw BackupError.keineDaten }
        let wegBackups = sortierteWegs.map(wegZuBackup)

        let backup = HausverwaltungBackup(
            version: 2,
            erstelltAm: Date(),
            weg: wegBackups.first,
            wegs: wegBackups,
            eigentuemerProfile: eigentuemerProfile.map(eigentuemerZuBackup),
            abrechnungsZeilen: abrechnungsZeilen.map(zeileZuBackup),
            aenderungsLog: aenderungsLog.map(logZuBackup),
            adminPinHash: adminPinHash
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(backup)
            let monat = Calendar.current.component(.month, from: Date())
            let basisName = "HV\(neuestesWeg.abrechnungsjahr)-\(monat)"
            let dateiName = Self.eindeutigerDateiname(
                basisName: basisName,
                extensionName: "json",
                in: FileManager.default.temporaryDirectory
            )
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(dateiName)
            try data.write(to: url)
            return url
        } catch let e as EncodingError {
            throw BackupError.encodingFehler(e)
        } catch {
            throw BackupError.speichernFehler(error)
        }
    }

    // MARK: - Import

    /// Liest eine Backup-Datei ein und gibt den Inhalt zurück (noch kein Speichern).
    func ladeBackup(von url: URL) throws -> HausverwaltungBackup {
        do {
            let data = try Data(contentsOf: url)
            if data.isEmpty {
                throw BackupError.ungueltigeDatei("Die Datei ist leer oder noch nicht vollständig verfügbar.")
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(HausverwaltungBackup.self, from: data)
        } catch let error as BackupError {
            throw error
        } catch let e as DecodingError {
            throw BackupError.decodingFehler(e)
        } catch {
            throw BackupError.lesenFehler(error)
        }
    }

    /// Stellt ein Backup wieder her: löscht alle alten Daten und importiert das Backup.
    func wiederherstellenBackup(
        _ backup: HausverwaltungBackup,
        modelContext: ModelContext
    ) throws {
        // Abwaertskompatibel: alte Backups enthalten nur 'weg', neue enthalten 'wegs'.
        let wegBackups: [WEGBackup]
        if let alle = backup.wegs, !alle.isEmpty {
            wegBackups = alle
        } else if let einzel = backup.weg {
            wegBackups = [einzel]
        } else {
            wegBackups = []
        }

        guard !wegBackups.isEmpty else { throw BackupError.keineDaten }

        let jahreImBackup = Set(wegBackups.map { $0.abrechnungsjahr })

        // Nur betroffene Jahre ersetzen, andere Jahre bleiben unberührt.
        let bestehendeWegs = try modelContext.fetch(FetchDescriptor<WEG>())
        for weg in bestehendeWegs where jahreImBackup.contains(weg.abrechnungsjahr) {
            modelContext.delete(weg)
        }

        let bestehendeProfile = try modelContext.fetch(FetchDescriptor<EigentuemerProfil>())
        for profil in bestehendeProfile where jahreImBackup.contains(profil.abrechnungsjahr) {
            modelContext.delete(profil)
        }

        let bestehendeZeilen = try modelContext.fetch(FetchDescriptor<AbrechnungsZeileKonfiguration>())
        for zeile in bestehendeZeilen where jahreImBackup.contains(zeile.abrechnungsjahr) {
            modelContext.delete(zeile)
        }

        for wegBackup in wegBackups {
            let weg = backupZuWEG(wegBackup, modelContext: modelContext)
            modelContext.insert(weg)
        }

        // Eigentümer-Profile
        for p in backup.eigentuemerProfile where jahreImBackup.contains(p.abrechnungsjahr) {
            modelContext.insert(backupZuEigentuemer(p))
        }

        // Abrechnungszeilen
        for z in backup.abrechnungsZeilen where jahreImBackup.contains(z.abrechnungsjahr) {
            modelContext.insert(backupZuZeile(z))
        }

        // Änderungslog
        let bestehendeLogIDs = Set((try modelContext.fetch(FetchDescriptor<AenderungsLog>())).map { $0.id })
        for l in backup.aenderungsLog where !bestehendeLogIDs.contains(l.id) {
            modelContext.insert(backupZuLog(l))
        }

        // Admin-PIN
        if let hash = backup.adminPinHash {
            let vorhandeneAdmin = try modelContext.fetch(FetchDescriptor<AdminEinstellungen>())
            if let admin = vorhandeneAdmin.first {
                admin.pinHash = hash
            } else {
                let admin = AdminEinstellungen(pinHash: hash)
                modelContext.insert(admin)
            }
        }

        try modelContext.save()
    }

    // MARK: - Private Hilfsmethoden: Modell → Backup

    private func wegZuBackup(_ weg: WEG) -> WEGBackup {
        WEGBackup(
            id: weg.id,
            name: weg.name,
            adresse: weg.adresse,
            abrechnungsjahr: weg.abrechnungsjahr,
            abgeschlossen: weg.abgeschlossen,
            abgeschlossenAm: weg.abgeschlossenAm,
            istMusterjahr: weg.istMusterjahr,
            brennstoffverbrauchKwh: weg.brennstoffverbrauchKwh,
            faktorProKwhEuro: weg.faktorProKwhEuro,
            verbrauchHeizungKwh: weg.verbrauchHeizungKwh,
            verbrauchWarmwasserKwh: weg.verbrauchWarmwasserKwh,
            gesamtwasserbetragLtRechnungEuro: weg.gesamtwasserbetragLtRechnungEuro,
            niederschlagswasserEuro: weg.niederschlagswasserEuro,
            verguetungHmtEuro: weg.verguetungHmtEuro,
            heizungWartungRepEuro: weg.heizungWartungRepEuro,
            schornsteinfegerEuro: weg.schornsteinfegerEuro,
            wartungBaurEuro: weg.wartungBaurEuro,
            allgemeinStromEuro: weg.allgemeinStromEuro,
            muellGebuehrenEuro: weg.muellGebuehrenEuro,
            muellGesamtPersonen: weg.muellGesamtPersonen,
            versicherungGebaeudeMitFeuerEuro: weg.versicherungGebaeudeMitFeuerEuro,
            versicherungHausHaftpflichtEuro: weg.versicherungHausHaftpflichtEuro,
            hausUndGrundEuro: weg.hausUndGrundEuro,
            nebenkostenGeldverkehrEuro: weg.nebenkostenGeldverkehrEuro,
            reparaturenAnschaffungenEuro: weg.reparaturenAnschaffungenEuro,
            ruecklagenEuro: weg.ruecklagenEuro,
            kontoAktuellEuro: weg.kontoAktuellEuro,
            hauptwasserZaehlerAnfang: weg.hauptwasserZaehlerAnfang,
            hauptwasserZaehlerEnde: weg.hauptwasserZaehlerEnde,
            abrechnungsHeaderTitel: weg.abrechnungsHeaderTitel,
            abrechnungsHeaderUntertitel: weg.abrechnungsHeaderUntertitel,
            abrechnungsHeaderPunkteText: weg.abrechnungsHeaderPunkteText,
            standardVerteilungsschluesselRaw: weg.standardVerteilungsschluesselRaw,
            ausgabenKategorienRaw: weg.ausgabenKategorienRaw,
            hausverwalterName: weg.hausverwalterName,
            hausverwalterStrasse: weg.hausverwalterStrasse,
            hausverwalterPlz: weg.hausverwalterPlz,
            hausverwalterOrt: weg.hausverwalterOrt,
            hausverwalterTelefon: weg.hausverwalterTelefon,
            hausverwalterEmail: weg.hausverwalterEmail,
            hausverwalterArtRaw: weg.hausverwalterArtRaw,
            hausverwalterGewaehltAm: weg.hausverwalterGewaehltAm,
            abrechnungszeitraumVon: weg.abrechnungszeitraumVon,
            abrechnungszeitraumBis: weg.abrechnungszeitraumBis,
            wegLogoBildData: weg.wegLogoBildData,
            pdfSchriftGroesseRaw: weg.pdfSchriftGroesseRaw,
            pdfRandBreiteRaw: weg.pdfRandBreiteRaw,
            pdfHeaderFarbeRaw: weg.pdfHeaderFarbeRaw,
            pdfFusszeileEinblenden: weg.pdfFusszeileEinblenden,
            pdfLogoPositionRaw: weg.pdfLogoPositionRaw,
            pdfLogoHoehePt: weg.pdfLogoHoehePt,
            pdfLogoSkalierung: weg.pdfLogoSkalierung,
            pdfLogoOffsetY: weg.pdfLogoOffsetY,
            pdfTitelAbstandOben: weg.pdfTitelAbstandOben,
            pdfTabellenStartOffsetY: weg.pdfTabellenStartOffsetY,
            pdfKopfzeileText: weg.pdfKopfzeileText,
            pdfKopfzeileOffsetY: weg.pdfKopfzeileOffsetY,
            pdfAdresseOffsetX: weg.pdfAdresseOffsetX,
            pdfAdresseOffsetY: weg.pdfAdresseOffsetY,
            pdfFusszeile1Text: weg.pdfFusszeile1Text,
            pdfFusszeile2Text: weg.pdfFusszeile2Text,
            pdfFusszeile1OffsetY: weg.pdfFusszeile1OffsetY,
            pdfFusszeile2OffsetY: weg.pdfFusszeile2OffsetY,
            wohnungen: weg.wohnungen.map(wohnungZuBackup),
            ausgaben: weg.ausgaben.map(ausgabeZuBackup),
            auslagenEintraege: weg.auslagenEintraege.map(auslagenEintragZuBackup)
        )
    }

    private func wohnungZuBackup(_ w: Wohnung) -> WohnungBackup {
        WohnungBackup(
            id: w.id,
            eigentuemer: w.eigentuemer,
            wohnungsnummer: w.wohnungsnummer,
            flaeche_qm: w.flaeche_qm,
            personenanzahl: w.personenanzahl,
            eigentumsanteilTausendstel: w.eigentumsanteilTausendstel,
            email: w.email,
            heizPunkteAnfang: w.heizPunkteAnfang,
            heizPunkteEnde: w.heizPunkteEnde,
            wasserWohnungZaehlerAnfang: w.wasserWohnungZaehlerAnfang,
            wasserWohnungZaehlerEnde: w.wasserWohnungZaehlerEnde,
            wasserWaschkuecheZaehlerAnfang: w.wasserWaschkuecheZaehlerAnfang,
            wasserWaschkuecheZaehlerEnde: w.wasserWaschkuecheZaehlerEnde,
            heizkostenverteiler: w.heizkostenverteiler.map(hkvZuBackup),
            wasserzaehler: w.wasserzaehler.map(wasserZuBackup),
            zahlungen: w.zahlungen.map(zahlungZuBackup),
            abrechnungsErgebnis: w.abrechnungsErgebnis.map(ergebnisZuBackup)
        )
    }

    private func hkvZuBackup(_ h: HeizkostenverteilerZaehler) -> HKVBackup {
        HKVBackup(id: h.id, nummer: h.nummer, bezeichnung: h.bezeichnung,
                  heizungstyp: h.heizungstyp, hinweis: h.hinweis, datum: h.datum,
                  faktor: h.faktor, ablesewertNeu: h.ablesewertNeu, verbrauchPunkte: h.verbrauchPunkte)
    }

    private func wasserZuBackup(_ w: Wasserzaehler) -> WasserzaehlerBackup {
        WasserzaehlerBackup(id: w.id, nummer: w.nummer, art: w.art.rawValue,
                            bezeichnung: w.bezeichnung, typ: w.typ, datum: w.datum,
                            ablesewertAlt: w.ablesewertAlt, ablesewertNeu: w.ablesewertNeu, faktor: w.faktor)
    }

    private func zahlungZuBackup(_ z: ZahlungsItem) -> ZahlungsItemBackup {
        ZahlungsItemBackup(id: z.id, kostenart: z.kostenart, betrag: z.betrag, monat: z.monat)
    }

    private func ausgabeZuBackup(_ a: AusgabenItem) -> AusgabenItemBackup {
        AusgabenItemBackup(id: a.id, kategorie: a.kategorie, monat: a.monat, betrag: a.betrag)
    }
    
    private func auslagenEintragZuBackup(_ a: AuslagenEintrag) -> AuslagenEintragBackup {
        AuslagenEintragBackup(
            id: a.id,
            monat: a.monat,
            betrag: a.betrag,
            verwendungszweck: a.verwendungszweck,
            kaufort: a.kaufort,
            datum: a.datum
        )
    }

    private func ergebnisZuBackup(_ e: AbrechnungsErgebnis) -> AbrechnungsErgebnisBackup {
        AbrechnungsErgebnisBackup(
            id: e.id,
            heizungAnteil30Prozent: e.heizungAnteil30Prozent,
            heizungAnteil70Prozent: e.heizungAnteil70Prozent,
            heizungGesamt: e.heizungGesamt,
            wasserAnteil30Prozent: e.wasserAnteil30Prozent,
            wasserAnteil70Prozent: e.wasserAnteil70Prozent,
            wasserGesamt: e.wasserGesamt,
            kaltwasserGesamt: e.kaltwasserGesamt,
            sonstigeKosten: e.sonstigeKosten,
            zahlungsabweichung: e.zahlungsabweichung,
            berechnungsDatum: e.berechnungsDatum
        )
    }

    private func eigentuemerZuBackup(_ p: EigentuemerProfil) -> EigentuemerProfilBackup {
        EigentuemerProfilBackup(
            id: p.id, abrechnungsjahr: p.abrechnungsjahr,
            vorname: p.vorname, nachname: p.nachname,
            strasse: p.strasse, plz: p.plz, ort: p.ort,
            wohnungsnummer: p.wohnungsnummer,
            eigentumsanteilTausendstel: p.eigentumsanteilTausendstel,
            nutzungsart: p.nutzungsartSicher.rawValue,
            mieterName: p.mieterName,
            haushaltPersonen: p.haushaltPersonen,
            geburtsdatum: p.geburtsdatum,
            notfallkontakt: p.notfallkontakt,
            notfallkontaktTelefon: p.notfallkontaktTelefon,
            telefon: p.telefon,
            email: p.email
        )
    }

    private func zeileZuBackup(_ z: AbrechnungsZeileKonfiguration) -> AbrechnungsZeileBackup {
        AbrechnungsZeileBackup(
            id: z.id, abrechnungsjahr: z.abrechnungsjahr, name: z.name,
            gesamtbetragEuro: z.gesamtbetragEuro, schluesselArt: z.schluesselArt.rawValue,
            istGlobal: z.istGlobal, wohnungsnummer: z.wohnungsnummer,
            gesamtSchluesselManuell: z.gesamtSchluesselManuell,
            wohnungsSchluesselManuell: z.wohnungsSchluesselManuell,
            sortierung: z.sortierung, aktiv: z.aktiv,
            systemCode: z.systemCode,
            istStandard: z.istStandard,
            betragQuellenRaw: z.betragQuellenRaw,
            schluesselGesamtQuelleRaw: z.schluesselGesamtQuelleRaw,
            schluesselWertQuelleRaw: z.schluesselWertQuelleRaw,
            wohnungsBetragQuelleRaw: z.wohnungsBetragQuelleRaw,
            schluesselBezeichnungOverride: z.schluesselBezeichnungOverride,
            anteilsModellRaw: z.anteilsModellRaw,
            wohnungsSchluesselManuellMapRaw: z.wohnungsSchluesselManuellMapRaw
        )
    }

    private func logZuBackup(_ l: AenderungsLog) -> AenderungsLogBackup {
        AenderungsLogBackup(
            id: l.id, datum: l.datum, bereich: l.bereich,
            wohnungsnummer: l.wohnungsnummer, eigentuemer: l.eigentuemer,
            zaehlernummer: l.zaehlernummer, feldname: l.feldname,
            altWert: l.altWert, neuWert: l.neuWert, grund: l.grund
        )
    }

    // MARK: - Private Hilfsmethoden: Backup → Modell

    private func backupZuWEG(_ b: WEGBackup, modelContext: ModelContext) -> WEG {
        let weg = WEG(name: b.name, adresse: b.adresse, abrechnungsjahr: b.abrechnungsjahr)
        weg.id = b.id
        weg.abgeschlossen = b.abgeschlossen
        weg.abgeschlossenAm = b.abgeschlossenAm
        weg.istMusterjahr = b.istMusterjahr ?? false
        weg.brennstoffverbrauchKwh = b.brennstoffverbrauchKwh
        weg.faktorProKwhEuro = b.faktorProKwhEuro
        weg.verbrauchHeizungKwh = b.verbrauchHeizungKwh
        weg.verbrauchWarmwasserKwh = b.verbrauchWarmwasserKwh
        weg.gesamtwasserbetragLtRechnungEuro = b.gesamtwasserbetragLtRechnungEuro
        weg.niederschlagswasserEuro = b.niederschlagswasserEuro
        weg.verguetungHmtEuro = b.verguetungHmtEuro
        weg.heizungWartungRepEuro = b.heizungWartungRepEuro
        weg.schornsteinfegerEuro = b.schornsteinfegerEuro
        weg.wartungBaurEuro = b.wartungBaurEuro
        weg.allgemeinStromEuro = b.allgemeinStromEuro
        weg.muellGebuehrenEuro = b.muellGebuehrenEuro
        weg.muellGesamtPersonen = b.muellGesamtPersonen
        weg.versicherungGebaeudeMitFeuerEuro = b.versicherungGebaeudeMitFeuerEuro
        weg.versicherungHausHaftpflichtEuro = b.versicherungHausHaftpflichtEuro
        weg.hausUndGrundEuro = b.hausUndGrundEuro
        weg.nebenkostenGeldverkehrEuro = b.nebenkostenGeldverkehrEuro
        weg.reparaturenAnschaffungenEuro = b.reparaturenAnschaffungenEuro
        weg.ruecklagenEuro = b.ruecklagenEuro
        weg.kontoAktuellEuro = b.kontoAktuellEuro
        weg.hauptwasserZaehlerAnfang = b.hauptwasserZaehlerAnfang
        weg.hauptwasserZaehlerEnde = b.hauptwasserZaehlerEnde
        weg.abrechnungsHeaderTitel = b.abrechnungsHeaderTitel
        weg.abrechnungsHeaderUntertitel = b.abrechnungsHeaderUntertitel
        weg.abrechnungsHeaderPunkteText = b.abrechnungsHeaderPunkteText
        weg.standardVerteilungsschluesselRaw = b.standardVerteilungsschluesselRaw
        weg.ausgabenKategorienRaw = b.ausgabenKategorienRaw ?? ""

        weg.hausverwalterName = b.hausverwalterName ?? ""
        weg.hausverwalterStrasse = b.hausverwalterStrasse ?? ""
        weg.hausverwalterPlz = b.hausverwalterPlz ?? ""
        weg.hausverwalterOrt = b.hausverwalterOrt ?? ""
        weg.hausverwalterTelefon = b.hausverwalterTelefon ?? ""
        weg.hausverwalterEmail = b.hausverwalterEmail ?? ""
        if let artRaw = b.hausverwalterArtRaw {
            weg.hausverwalterArtRaw = artRaw
        }
        if let gewaehltAm = b.hausverwalterGewaehltAm {
            weg.hausverwalterGewaehltAm = gewaehltAm
        }
        if let von = b.abrechnungszeitraumVon {
            weg.abrechnungszeitraumVon = von
        }
        if let bis = b.abrechnungszeitraumBis {
            weg.abrechnungszeitraumBis = bis
        }
        if let logoData = b.wegLogoBildData {
            weg.wegLogoBildData = logoData
        }
        if let v = b.pdfSchriftGroesseRaw { weg.pdfSchriftGroesseRaw = v }
        if let v = b.pdfRandBreiteRaw     { weg.pdfRandBreiteRaw = v }
        if let v = b.pdfHeaderFarbeRaw    { weg.pdfHeaderFarbeRaw = v }
        if let v = b.pdfFusszeileEinblenden { weg.pdfFusszeileEinblenden = v }
        if let v = b.pdfLogoPositionRaw      { weg.pdfLogoPositionRaw = v }
        if let v = b.pdfLogoHoehePt          { weg.pdfLogoHoehePt = v }
        if let v = b.pdfLogoSkalierung       { weg.pdfLogoSkalierung = v }
        if let v = b.pdfLogoOffsetY          { weg.pdfLogoOffsetY = v }
        if let v = b.pdfTitelAbstandOben     { weg.pdfTitelAbstandOben = v }
        if let v = b.pdfTabellenStartOffsetY { weg.pdfTabellenStartOffsetY = v }
        if let v = b.pdfKopfzeileText        { weg.pdfKopfzeileText = v }
        if let v = b.pdfKopfzeileOffsetY     { weg.pdfKopfzeileOffsetY = v }
        if let v = b.pdfAdresseOffsetX       { weg.pdfAdresseOffsetX = v }
        if let v = b.pdfAdresseOffsetY       { weg.pdfAdresseOffsetY = v }
        if let v = b.pdfFusszeile1Text       { weg.pdfFusszeile1Text = v }
        if let v = b.pdfFusszeile2Text       { weg.pdfFusszeile2Text = v }
        if let v = b.pdfFusszeile1OffsetY    { weg.pdfFusszeile1OffsetY = v }
        if let v = b.pdfFusszeile2OffsetY    { weg.pdfFusszeile2OffsetY = v }

        for wb in b.wohnungen {
            let wohnung = backupZuWohnung(wb)
            modelContext.insert(wohnung)
            weg.wohnungen.append(wohnung)
        }

        // Abwaertskompatibel: Bei alten Backups kann 'ausgaben' fehlen.
        for ab in b.ausgaben ?? [] {
            let a = AusgabenItem(kategorie: ab.kategorie, monat: ab.monat, betrag: ab.betrag, weg: weg)
            a.id = ab.id
            modelContext.insert(a)
            weg.ausgaben.append(a)
        }
        
        for ae in b.auslagenEintraege ?? [] {
            let a = AuslagenEintrag(
                monat: ae.monat,
                betrag: ae.betrag,
                verwendungszweck: ae.verwendungszweck,
                kaufort: ae.kaufort,
                datum: ae.datum,
                weg: weg
            )
            a.id = ae.id
            modelContext.insert(a)
            weg.auslagenEintraege.append(a)
        }

        // Falls keine Headerliste mitgegeben wurde, aus vorhandenen Ausgaben ableiten.
        if weg.ausgabenKategorienRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let kategorien = Array(Set(weg.ausgaben.map { $0.kategorie.trimmingCharacters(in: .whitespacesAndNewlines) }))
                .filter { !$0.isEmpty }
                .sorted()
            if !kategorien.isEmpty {
                weg.ausgabenKategorienRaw = kategorien.joined(separator: "|")
            }
        }
        return weg
    }

    private func backupZuWohnung(_ b: WohnungBackup) -> Wohnung {
        let w = Wohnung(eigentuemer: b.eigentuemer, wohnungsnummer: b.wohnungsnummer,
                        flaeche_qm: b.flaeche_qm, personenanzahl: b.personenanzahl, eigentumsanteilTausendstel: b.eigentumsanteilTausendstel)
        w.id = b.id
        w.email = b.email
        w.heizPunkteAnfang = b.heizPunkteAnfang
        w.heizPunkteEnde = b.heizPunkteEnde
        w.wasserWohnungZaehlerAnfang = b.wasserWohnungZaehlerAnfang
        w.wasserWohnungZaehlerEnde = b.wasserWohnungZaehlerEnde
        w.wasserWaschkuecheZaehlerAnfang = b.wasserWaschkuecheZaehlerAnfang
        w.wasserWaschkuecheZaehlerEnde = b.wasserWaschkuecheZaehlerEnde

        for hb in b.heizkostenverteiler {
            let h = HeizkostenverteilerZaehler(
                nummer: hb.nummer, bezeichnung: hb.bezeichnung,
                heizungstyp: hb.heizungstyp, hinweis: hb.hinweis, datum: hb.datum,
                faktor: hb.faktor, ablesewertNeu: hb.ablesewertNeu,
                verbrauchPunkte: hb.verbrauchPunkte, wohnung: w
            )
            h.id = hb.id
            w.heizkostenverteiler.append(h)
        }

        for wb in b.wasserzaehler {
            let art = WasserzaehlerArt(rawValue: wb.art) ?? .kaltwasser
            let wz = Wasserzaehler(
                nummer: wb.nummer, art: art, bezeichnung: wb.bezeichnung,
                typ: wb.typ, datum: wb.datum,
                ablesewertAlt: wb.ablesewertAlt, ablesewertNeu: wb.ablesewertNeu,
                faktor: wb.faktor, wohnung: w
            )
            wz.id = wb.id
            w.wasserzaehler.append(wz)
        }

        for zb in b.zahlungen {
            let z = ZahlungsItem(kostenart: zb.kostenart, betrag: zb.betrag, monat: zb.monat)
            z.id = zb.id
            w.zahlungen.append(z)
        }

        if let eb = b.abrechnungsErgebnis {
            let e = AbrechnungsErgebnis(wohnung: w)
            e.id = eb.id
            e.heizungAnteil30Prozent = eb.heizungAnteil30Prozent
            e.heizungAnteil70Prozent = eb.heizungAnteil70Prozent
            e.heizungGesamt = eb.heizungGesamt
            e.wasserAnteil30Prozent = eb.wasserAnteil30Prozent
            e.wasserAnteil70Prozent = eb.wasserAnteil70Prozent
            e.wasserGesamt = eb.wasserGesamt
            e.kaltwasserGesamt = eb.kaltwasserGesamt
            e.sonstigeKosten = eb.sonstigeKosten
            e.zahlungsabweichung = eb.zahlungsabweichung
            e.berechnungsDatum = eb.berechnungsDatum
            w.abrechnungsErgebnis = e
        }

        return w
    }

    private func backupZuEigentuemer(_ b: EigentuemerProfilBackup) -> EigentuemerProfil {
        let p = EigentuemerProfil(
            abrechnungsjahr: b.abrechnungsjahr,
            vorname: b.vorname, nachname: b.nachname,
            strasse: b.strasse, plz: b.plz, ort: b.ort,
            wohnungsnummer: b.wohnungsnummer,
            eigentumsanteilTausendstel: b.eigentumsanteilTausendstel,
            nutzungsart: .eigennutzung,
            mieterName: b.mieterName,
            haushaltPersonen: b.haushaltPersonen,
            geburtsdatum: b.geburtsdatum,
            notfallkontakt: b.notfallkontakt,
            notfallkontaktTelefon: b.notfallkontaktTelefon,
            telefon: b.telefon,
            email: b.email
        )
        p.id = b.id
        p.setNutzungsart(EigentuemerNutzungsart(rawValue: b.nutzungsart) ?? .eigennutzung)
        return p
    }

    private func backupZuZeile(_ b: AbrechnungsZeileBackup) -> AbrechnungsZeileKonfiguration {
        let z = AbrechnungsZeileKonfiguration(
            abrechnungsjahr: b.abrechnungsjahr, name: b.name,
            gesamtbetragEuro: b.gesamtbetragEuro,
            schluesselArt: VerteilungsschluesselArt(rawValue: b.schluesselArt) ?? .wohneinheiten,
            istGlobal: b.istGlobal, wohnungsnummer: b.wohnungsnummer,
            gesamtSchluesselManuell: b.gesamtSchluesselManuell,
            wohnungsSchluesselManuell: b.wohnungsSchluesselManuell,
            sortierung: b.sortierung, aktiv: b.aktiv
        )
        z.id = b.id
        z.systemCode = b.systemCode
        z.istStandard = b.istStandard
        z.betragQuellenRaw = b.betragQuellenRaw
        z.schluesselGesamtQuelleRaw = b.schluesselGesamtQuelleRaw
        z.schluesselWertQuelleRaw = b.schluesselWertQuelleRaw
        z.wohnungsBetragQuelleRaw = b.wohnungsBetragQuelleRaw
        z.schluesselBezeichnungOverride = b.schluesselBezeichnungOverride
        z.anteilsModellRaw = b.anteilsModellRaw
        z.wohnungsSchluesselManuellMapRaw = b.wohnungsSchluesselManuellMapRaw ?? ""
        return z
    }

    private func backupZuLog(_ b: AenderungsLogBackup) -> AenderungsLog {
        let l = AenderungsLog(
            bereich: b.bereich, wohnungsnummer: b.wohnungsnummer,
            eigentuemer: b.eigentuemer, zaehlernummer: b.zaehlernummer,
            feldname: b.feldname, altWert: b.altWert, neuWert: b.neuWert, grund: b.grund
        )
        l.id = b.id
        l.datum = b.datum
        return l
    }

    // MARK: - Hilfsmethoden

    private static func datumStempel() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }

    private static func eindeutigerDateiname(basisName: String, extensionName: String, in ordner: URL) -> String {
        let fm = FileManager.default
        let ext = extensionName.trimmingCharacters(in: .whitespacesAndNewlines)
        var kandidat = "\(basisName).\(ext)"
        var zaehler = 1

        while fm.fileExists(atPath: ordner.appendingPathComponent(kandidat).path) {
            kandidat = "\(basisName)-\(zaehler).\(ext)"
            zaehler += 1
        }
        return kandidat
    }
}
