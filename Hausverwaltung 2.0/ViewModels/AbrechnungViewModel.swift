//
//  AbrechnungViewModel.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftData
import SwiftUI
import Combine

@MainActor
class AbrechnungViewModel: ObservableObject {
    @Published var selectedJahr: Int
    @Published var weg: WEG?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext

    private let standardAusgabenKategorien: [String] = [
        "Strom VaFa",
        "fairenergie Gas",
        "Schornstein",
        "Konto",
        "Müll",
        "Wasser",
        "Haus und Grund",
        "Baur",
        "Auslagen HM",
        "HMT",
        "WEG Rücklagen"
    ]

    private let hkvMetaByNummer: [String: (heizungstyp: String, hinweis: String)] = [
        "90878776": ("Typ22 900mm", ""),
        "90878777": ("Typ21 600mm", ""),
        "90878834": ("Typ20 800mm", "erneuert"),
        "90878779": ("Typ20 800mm", ""),
        "90878835": ("Typ22 900mm", "erneuert"),
        "90878786": ("Typ22 1000mm", ""),
        "90878787": ("Typ21 800mm", ""),
        "90878788": ("Typ33 700mm", ""),
        "90878790": ("Typ21 400mm", ""),
        "90878791": ("Typ21 1200mm", ""),
        "90878792": ("Typ21 800mm", ""),
        "90878793": ("Typ21 800mm", ""),
        "90878794": ("Typ21 400mm", ""),
        "90878795": ("Sondertyp 1700mm", ""),
        "90878796": ("Typ21 1000mm", ""),
        "90878805": ("Typ21 500mm", ""),
        "90878806": ("Typ22 900mm", ""),
        "90878807": ("Typ20 700mm", ""),
        "90878808": ("Typ20 700mm", ""),
        "90878809": ("Typ21 500mm", ""),
        "90878810": ("Typ22 700mm", ""),
        "90878811": ("Typ22 1000mm", ""),
        "90878812": ("Typ20 900mm", ""),
        "90878797": ("Typ21 500mm", ""),
        "90878798": ("Typ33 500mm", ""),
        "90878799": ("Typ33 1200mmx330", ""),
        "90878800": ("Typ21 700mmx330", ""),
        "90878801": ("Typ22 1100mm", ""),
        "90878802": ("Typ22 500mm", ""),
        "90878803": ("Typ33 500mm", ""),
        "90878804": ("Typ22 700mm", ""),
        "90878819": ("Typ21 500mm", ""),
        "90878813": ("Typ33 500mm", ""),
        "90878814": ("Typ22 500mm", ""),
        "90878815": ("Typ33 1200mm", ""),
        "90878816": ("Typ21 700mm", ""),
        "90878817": ("Typ22 1100mm", ""),
        "90878818": ("Typ22 700mm", ""),
        "90878820": ("Typ22 600mm", ""),
        "90878821": ("Typ22 500mm", ""),
        "90878822": ("Typ21 700mm", ""),
        "90878823": ("Typ22 700mm", ""),
        "90878824": ("Typ22 700mm", ""),
        "90878825": ("Typ22 600mm", ""),
        "90878826": ("Sondertyp 1170mm", ""),
        "90878827": ("Typ22 600mm", ""),
        "90878828": ("Typ22 600mm", ""),
        "90878829": ("Typ33 800mm", ""),
        "90878830": ("Typ33 800mm", ""),
        "90878831": ("Typ22 600mm", ""),
    ]
    
    init(modelContext: ModelContext, jahr: Int = 2025) {
        self.modelContext = modelContext
        self.selectedJahr = jahr
        loadAbrechnungData()
    }
    
    // MARK: - Daten laden/speichern
    
    func loadAbrechnungData() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Versuche WEG für das aktuelle Jahr zu laden
            var descriptor = FetchDescriptor<WEG>()
            descriptor.sortBy = [SortDescriptor(\.abrechnungsjahr, order: .reverse)]
            
            let wegs = try modelContext.fetch(descriptor)
            // Filtere nach aktuellem Jahr
            self.weg = wegs.first { $0.abrechnungsjahr == selectedJahr }
            
            // Nur wenn wirklich noch gar keine Jahresdaten existieren, Seed anlegen.
            if self.weg == nil {
                if wegs.isEmpty {
                    createMusterjahr()
                } else {
                    // Bevorzuge das neueste echte (nicht Demo-) Jahr
                    let echteWegs = wegs.filter { !$0.istMusterjahr }
                    if let neuestes = echteWegs.first ?? wegs.first {
                        self.selectedJahr = neuestes.abrechnungsjahr
                        self.weg = neuestes
                    }
                }
            }

            ensureEigentuemerProfile()
            normalisiereVerknuepfteStammdaten()
            ensureStandardAbrechnungsZeilen()
        } catch {
            errorMessage = "Fehler beim Laden der Abrechnung: \(error.localizedDescription)"
        }
    }
    
    func saveWEG() {
        do {
            if weg != nil {
                try modelContext.save()
            }
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }

    // MARK: - Eigentümer-Stammdaten

    private func splitName(_ fullName: String) -> (vorname: String, nachname: String) {
        let teile = fullName
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !teile.isEmpty else { return ("", "") }
        if teile.count == 1 { return ("", teile[0]) }
        let nachname = teile.last ?? ""
        let vorname = teile.dropLast().joined(separator: " ")
        return (vorname, nachname)
    }

    func eigentuemerProfileImAktuellenJahr() -> [EigentuemerProfil] {
        guard let weg = weg else { return [] }
        let alle = (try? modelContext.fetch(FetchDescriptor<EigentuemerProfil>())) ?? []
        return alle
            .filter { $0.abrechnungsjahr == weg.abrechnungsjahr }
            .sorted {
                if $0.nachname != $1.nachname { return $0.nachname.localizedCaseInsensitiveCompare($1.nachname) == .orderedAscending }
                return $0.vorname.localizedCaseInsensitiveCompare($1.vorname) == .orderedAscending
            }
    }

    func ensureEigentuemerProfile() {
        guard let weg = weg else { return }
        let bestehend = eigentuemerProfileImAktuellenJahr()
        let vorhandeneWohnungen = Set(bestehend.compactMap { $0.wohnungsnummer })
        var wurdeAngelegt = false

        for wohnung in weg.wohnungenSortiert where !vorhandeneWohnungen.contains(wohnung.wohnungsnummer) {
            let name = splitName(wohnung.eigentuemer)
            let profil = EigentuemerProfil(
                abrechnungsjahr: weg.abrechnungsjahr,
                vorname: name.vorname,
                nachname: name.nachname,
                strasse: "",
                plz: "",
                ort: "",
                wohnungsnummer: wohnung.wohnungsnummer,
                eigentumsanteilTausendstel: wohnung.eigentumsanteilTausendstel,
                nutzungsart: .eigennutzung,
                mieterName: "",
                haushaltPersonen: max(1, wohnung.personenanzahl),
                geburtsdatum: nil,
                notfallkontakt: "",
                notfallkontaktTelefon: "",
                telefon: "",
                email: wohnung.email ?? ""
            )
            modelContext.insert(profil)
            wurdeAngelegt = true
        }

        for profil in bestehend {
            guard let nummer = profil.wohnungsnummer,
                  let wohnung = weg.wohnungenSortiert.first(where: { $0.wohnungsnummer == nummer }) else { continue }
            if profil.haushaltPersonen != max(1, wohnung.personenanzahl) {
                profil.haushaltPersonen = max(1, wohnung.personenanzahl)
                wurdeAngelegt = true
            }
            if wohnung.eigentumsanteilTausendstel > 0 && profil.eigentumsanteilTausendstel != wohnung.eigentumsanteilTausendstel {
                profil.eigentumsanteilTausendstel = wohnung.eigentumsanteilTausendstel
                wurdeAngelegt = true
            }
        }

        if wurdeAngelegt {
            try? modelContext.save()
        }
    }

    private func normalisiereVerknuepfteStammdaten() {
        guard let weg else { return }
        let gesamtPersonen = AbrechnungsZeilenEngine.resolveHaushaltPersonenGesamt(
            in: weg,
            eigentuemerProfile: eigentuemerProfileImAktuellenJahr()
        )

        guard weg.muellGesamtPersonen != gesamtPersonen else { return }
        weg.muellGesamtPersonen = gesamtPersonen
        try? modelContext.save()
    }

    func createEigentuemerProfil() {
        guard let weg = weg else { return }
        let profil = EigentuemerProfil(
            abrechnungsjahr: weg.abrechnungsjahr,
            vorname: "",
            nachname: "",
            strasse: "",
            plz: "",
            ort: "",
            wohnungsnummer: weg.wohnungenSortiert.first?.wohnungsnummer,
            eigentumsanteilTausendstel: 0,
            nutzungsart: .eigennutzung,
            mieterName: "",
            haushaltPersonen: max(1, weg.wohnungenSortiert.first?.personenanzahl ?? 1),
            geburtsdatum: nil,
            notfallkontakt: "",
            notfallkontaktTelefon: "",
            telefon: "",
            email: ""
        )
        modelContext.insert(profil)
        try? modelContext.save()
        objectWillChange.send()
    }

    func ensureStandardAbrechnungsZeilen() {
        guard let weg = weg else { return }
        let vorhandene = (try? modelContext.fetch(FetchDescriptor<AbrechnungsZeileKonfiguration>())) ?? []
        let globaleImJahr = vorhandene.filter { $0.abrechnungsjahr == weg.abrechnungsjahr && $0.istGlobal }
        let standardZeilen = AbrechnungsZeilenEngine.standardZeilen(abrechnungsjahr: weg.abrechnungsjahr)

        var wurdeGeaendert = false
        for standard in standardZeilen {
            if let bestehend = globaleImJahr.first(where: { !$0.systemCode.isEmpty && $0.systemCode == standard.systemCode })
                ?? globaleImJahr.first(where: { $0.name == standard.name }) {
                bestehend.systemCode = standard.systemCode
                bestehend.istStandard = true
                bestehend.sortierung = standard.sortierung
                if bestehend.betragQuellenRaw.isEmpty {
                    bestehend.setBetragQuellen(standard.betragQuellen)
                }
                if bestehend.schluesselGesamtQuelleSicher == .none {
                    bestehend.setSchluesselGesamtQuelle(standard.schluesselGesamtQuelleSicher)
                }
                if bestehend.schluesselWertQuelleSicher == .none {
                    bestehend.setSchluesselWertQuelle(standard.schluesselWertQuelleSicher)
                }
                if bestehend.schluesselBezeichnungOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    bestehend.schluesselBezeichnungOverride = standard.schluesselBezeichnungOverride
                }
                if bestehend.wohnungsBetragQuelleSicher == .none {
                    bestehend.setWohnungsBetragQuelle(standard.wohnungsBetragQuelleSicher)
                }
                if bestehend.anteilsModellRaw.isEmpty {
                    bestehend.setAnteilsModell(standard.anteilsModellSicher)
                }
                wurdeGeaendert = true
            } else {
                modelContext.insert(standard)
                wurdeGeaendert = true
            }
        }

        if wurdeGeaendert {
            try? modelContext.save()
        }
    }

    func abrechnungsZeilen(fuer wohnung: Wohnung?) -> [AbrechnungsZeileKonfiguration] {
        guard let weg = weg else { return [] }
        let alle = (try? modelContext.fetch(FetchDescriptor<AbrechnungsZeileKonfiguration>())) ?? []
        return alle
            .filter { zeile in
                zeile.abrechnungsjahr == weg.abrechnungsjahr
                    && (zeile.istGlobal || zeile.wohnungsnummer == wohnung?.wohnungsnummer)
            }
            .sorted {
                if $0.sortierung != $1.sortierung { return $0.sortierung < $1.sortierung }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    @discardableResult
    func createAbrechnungsZeile(global: Bool, wohnung: Wohnung?) -> AbrechnungsZeileKonfiguration? {
        guard let weg = weg else { return nil }
        let nextSort = (abrechnungsZeilen(fuer: wohnung).map { $0.sortierung }.max() ?? -1) + 1
        let zeile = AbrechnungsZeileKonfiguration(
            abrechnungsjahr: weg.abrechnungsjahr,
            name: "Neue Abrechnungszeile",
            gesamtbetragEuro: 0,
            schluesselArt: VerteilungsschluesselArt.wohneinheiten,
            istGlobal: global,
            wohnungsnummer: global ? nil : wohnung?.wohnungsnummer,
            gesamtSchluesselManuell: 0,
            wohnungsSchluesselManuell: 0,
            sortierung: nextSort,
            aktiv: true
        )
        zeile.systemCode = ""
        zeile.istStandard = false
        modelContext.insert(zeile)
        try? modelContext.save()
        objectWillChange.send()
        return zeile
    }

    func deleteAbrechnungsZeile(_ zeile: AbrechnungsZeileKonfiguration) {
        modelContext.delete(zeile)
        try? modelContext.save()
        objectWillChange.send()
    }

    // MARK: - 📅 Jahresverwaltung

    /// Alle vorhandenen Abrechnungsjahre: echte Jahre absteigend, Musterjahr(e) ans Ende.
    var alleJahre: [Int] {
        let alle = (try? modelContext.fetch(FetchDescriptor<WEG>())) ?? []
        let echteJahre = alle.filter { !$0.istMusterjahr }.map { $0.abrechnungsjahr }.sorted(by: >)
        let musterJahre = alle.filter { $0.istMusterjahr }.map { $0.abrechnungsjahr }.sorted(by: >)
        return echteJahre + musterJahre
    }

    var neuestesJahr: Int? {
        let alle = (try? modelContext.fetch(FetchDescriptor<WEG>())) ?? []
        return alle.filter { !$0.istMusterjahr }.map { $0.abrechnungsjahr }.sorted(by: >).first
    }

    /// True, wenn das aktuell ausgewählte WEG ein Demo-/Musterjahr ist.
    var istMusterjahrAktiv: Bool {
        weg?.istMusterjahr == true
    }

    /// True, wenn noch kein Admin-PIN gesetzt wurde (= Demo-Modus).
    var istErsterStart: Bool {
        !adminAngelegegt
    }

    /// Gibt die Bezeichnung eines Jahres zurück – "Demo" für Musterjahre.
    func labelFuerJahrNummer(_ jahr: Int) -> String {
        let alle = (try? modelContext.fetch(FetchDescriptor<WEG>())) ?? []
        if alle.first(where: { $0.abrechnungsjahr == jahr })?.istMusterjahr == true {
            return "Demo"
        }
        return String(jahr)
    }

    var istHistorischesJahr: Bool {
        // Musterjahr ist nach PIN-Vergabe immer read-only
        if weg?.istMusterjahr == true, adminAngelegegt { return true }
        guard let neuestesJahr else { return false }
        return selectedJahr < neuestesJahr
    }

    var istJahrSchreibgeschuetzt: Bool {
        guard let weg else { return istHistorischesJahr }
        return weg.abgeschlossen || istHistorischesJahr
    }

    var schreibschutzHinweis: String {
        if istHistorischesJahr {
            return "Historisches Jahr \(selectedJahr) – nur Ansicht, keine Änderungen möglich."
        }
        if weg?.abgeschlossen == true {
            return "Dieses Jahr ist abgeschlossen – nur Lesezugriff."
        }
        return ""
    }

    /// Wechselt zum gewählten Jahr und lädt die zugehörigen Daten.
    func jahresWechsel(zu jahr: Int) {
        selectedJahr = jahr
        loadAbrechnungData()
    }

    /// Schließt das aktuelle Jahr ab (nur nach Admin-PIN).
    /// Danach ist das Jahr schreibgeschützt.
    @discardableResult
    func jahrAbschliessen(pin: String) -> Bool {
        guard adminPinPruefen(pin) else { return false }
        guard let weg = weg, !weg.abgeschlossen else { return false }
        weg.abgeschlossen = true
        weg.abgeschlossenAm = Date()
        // Audit-Log
        let eintrag = AenderungsLog(
            bereich: "Jahresabschluss",
            wohnungsnummer: 0,
            eigentuemer: "WEG",
            zaehlernummer: "-",
            feldname: "abgeschlossen",
            altWert: "offen",
            neuWert: "abgeschlossen",
            grund: "Jahresabschluss \(weg.abrechnungsjahr) durch Admin bestätigt"
        )
        modelContext.insert(eintrag)
        try? modelContext.save()
        return true
    }

    /// Legt ein neues Abrechnungsjahr auf Basis eines Vorjahres an.
    /// Übernimmt Stammdaten, Zähler, Fixkosten – setzt Messwerte und Zahlungen zurück.
    func neuesJahrAnlegen(basisJahr: Int) -> Bool {
        guard let basis = (try? modelContext.fetch(FetchDescriptor<WEG>()))?.first(where: { $0.abrechnungsjahr == basisJahr }) else {
            errorMessage = "Basis-Jahr \(basisJahr) nicht gefunden."
            return false
        }
        let neuesJahr = basisJahr + 1

        // Prüfen ob das neue Jahr schon existiert
        if (try? modelContext.fetch(FetchDescriptor<WEG>()))?.contains(where: { $0.abrechnungsjahr == neuesJahr }) == true {
            errorMessage = "Jahr \(neuesJahr) existiert bereits."
            return false
        }

        // Neues WEG-Objekt anlegen
        let neu = WEG(name: basis.name, adresse: basis.adresse, abrechnungsjahr: neuesJahr)

        // Fixkosten übernehmen
        neu.verguetungHmtEuro = basis.verguetungHmtEuro
        neu.heizungWartungRepEuro = basis.heizungWartungRepEuro
        neu.schornsteinfegerEuro = basis.schornsteinfegerEuro
        neu.wartungBaurEuro = basis.wartungBaurEuro
        neu.allgemeinStromEuro = basis.allgemeinStromEuro
        neu.muellGebuehrenEuro = basis.muellGebuehrenEuro
        neu.muellGesamtPersonen = basis.muellGesamtPersonen
        neu.versicherungGebaeudeMitFeuerEuro = basis.versicherungGebaeudeMitFeuerEuro
        neu.versicherungHausHaftpflichtEuro = basis.versicherungHausHaftpflichtEuro
        neu.hausUndGrundEuro = basis.hausUndGrundEuro
        neu.nebenkostenGeldverkehrEuro = basis.nebenkostenGeldverkehrEuro
        neu.reparaturenAnschaffungenEuro = basis.reparaturenAnschaffungenEuro
        neu.ruecklagenEuro = basis.ruecklagenEuro
        neu.ausgabenKategorienRaw = basis.ausgabenKategorienRaw
        // Hauptabrechnungswerte: leer → kommen aus neuen Rechnungen
        // Konto: leer
        // abgeschlossen: false (Standard)

        modelContext.insert(neu)

        // Wohnungen übernehmen
        for altWohnung in basis.wohnungenSortiert {
            let neueWohnung = Wohnung(
                eigentuemer: altWohnung.eigentuemer,
                wohnungsnummer: altWohnung.wohnungsnummer,
                flaeche_qm: altWohnung.flaeche_qm,
                personenanzahl: altWohnung.personenanzahl,
                eigentumsanteilTausendstel: altWohnung.eigentumsanteilTausendstel
            )
            neueWohnung.email = altWohnung.email

            // Wasserzähler: Nummern + Typen übernehmen, Alt = Vorjahres-Neu, Neu = 0
            for altZaehler in altWohnung.wasserzaehler {
                let neuerZaehler = Wasserzaehler(
                    nummer: altZaehler.nummer,
                    art: altZaehler.art,
                    bezeichnung: altZaehler.bezeichnung,
                    typ: altZaehler.typ,
                    ablesewertAlt: altZaehler.ablesewertNeu,  // Jahresübertrag
                    ablesewertNeu: 0,
                    faktor: altZaehler.faktor,
                    wohnung: neueWohnung
                )
                neueWohnung.wasserzaehler.append(neuerZaehler)
                modelContext.insert(neuerZaehler)
            }

            // HKV: Nummern + Typen übernehmen, Messwerte = 0
            for altHkv in altWohnung.heizkostenverteiler {
                let neuerHkv = HeizkostenverteilerZaehler(
                    nummer: altHkv.nummer,
                    bezeichnung: altHkv.bezeichnung,
                    heizungstyp: altHkv.heizungstyp,
                    hinweis: altHkv.hinweis,
                    faktor: altHkv.faktor,
                    ablesewertNeu: 0,
                    verbrauchPunkte: 0,
                    wohnung: neueWohnung
                )
                neueWohnung.heizkostenverteiler.append(neuerHkv)
                modelContext.insert(neuerHkv)
            }

            neu.wohnungen.append(neueWohnung)
            modelContext.insert(neueWohnung)
        }

        // Hauptwasserzähler: Alt = Vorjahres-Ende
        neu.hauptwasserZaehlerAnfang = basis.hauptwasserZaehlerEnde
        neu.hauptwasserZaehlerEnde = 0

        do {
            try modelContext.save()
            jahresWechsel(zu: neuesJahr)
            return true
        } catch {
            errorMessage = "Fehler beim Anlegen des neuen Jahres: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 🔐 Admin-PIN

        /// Gibt true zurück wenn ein Admin-PIN angelegt ist.
        var adminAngelegegt: Bool {
            (try? modelContext.fetch(FetchDescriptor<AdminEinstellungen>()))?.isEmpty == false
        }

        /// Gibt den gespeicherten PIN-Hash zurück (für Backup).
        var adminPinHash: String? {
            (try? modelContext.fetch(FetchDescriptor<AdminEinstellungen>()))?.first?.pinHash
        }

        /// Lädt WEG-Daten neu (nach Restore).
        func reload() {
            loadAbrechnungData()
        }

        /// Legt einen neuen Admin-PIN an (einmalig). Gibt false zurück wenn bereits einer existiert.
        @discardableResult
        func adminPinSetzen(_ pin: String) -> Bool {
            guard !adminAngelegegt else { return false }
            let eintrag = AdminEinstellungen(pinHash: AdminEinstellungen.hash(pin))
            modelContext.insert(eintrag)
            try? modelContext.save()
            return true
        }

        /// Prüft ob der eingegebene PIN korrekt ist.
        func adminPinPruefen(_ pin: String) -> Bool {
            guard let admin = (try? modelContext.fetch(FetchDescriptor<AdminEinstellungen>()))?.first else {
                return false
            }
            return admin.verify(pin)
        }

        /// Ändert den bestehenden Admin-PIN nach Verifikation des alten PINs.
        @discardableResult
        func adminPinAendern(alter pin: String, neuer neuerPin: String) -> Bool {
            guard let admin = (try? modelContext.fetch(FetchDescriptor<AdminEinstellungen>()))?.first,
                  admin.verify(pin) else { return false }
            admin.pinHash = AdminEinstellungen.hash(neuerPin)
            try? modelContext.save()
            return true
        }

        // MARK: - 📋 Audit-Log

        func logAenderung(bereich: String, wohnung: Wohnung, zaehlernummer: String,
                          feldname: String, altWert: String, neuWert: String, grund: String) {
            let eintrag = AenderungsLog(
                bereich: bereich,
                wohnungsnummer: wohnung.wohnungsnummer,
                eigentuemer: wohnung.eigentuemer,
                zaehlernummer: zaehlernummer,
                feldname: feldname,
                altWert: altWert,
                neuWert: neuWert,
                grund: grund
            )
            modelContext.insert(eintrag)
            try? modelContext.save()
        }

        // MARK: - 🗂 HKV-Tausch mit Historie

        /// Speichert den aktuellen HKV als Historieeintrag und aktualisiert die Felder mit neuen Werten.
        func hkvTauschen(zaehler: HeizkostenverteilerZaehler, wohnung: Wohnung,
                         neuerFaktor: Double, neuerAblesewert: Double, neueVerbrauchPunkte: Double,
                         grund: String) {
            // Historie-Snapshot anlegen
            let historie = HKVHistorieEintrag(von: zaehler, grund: grund)
            modelContext.insert(historie)

            // Audit-Log: Faktor
            if zaehler.faktor != neuerFaktor {
                logAenderung(bereich: "HKV", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Faktor",
                             altWert: String(zaehler.faktor), neuWert: String(neuerFaktor),
                             grund: grund)
            }
            // Audit-Log: Ablesewert
            if zaehler.ablesewertNeu != neuerAblesewert {
                logAenderung(bereich: "HKV", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Ablesewert",
                             altWert: String(zaehler.ablesewertNeu), neuWert: String(neuerAblesewert),
                             grund: grund)
            }
            // Audit-Log: Verbrauchspunkte
            if zaehler.verbrauchPunkte != neueVerbrauchPunkte {
                logAenderung(bereich: "HKV", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Verbrauchspunkte",
                             altWert: String(zaehler.verbrauchPunkte), neuWert: String(neueVerbrauchPunkte),
                             grund: grund)
            }

            // Werte aktualisieren
            zaehler.faktor = neuerFaktor
            zaehler.ablesewertNeu = neuerAblesewert
            zaehler.verbrauchPunkte = neueVerbrauchPunkte
            zaehler.datum = deKurzDatum(Date())
            try? modelContext.save()
        }

        // MARK: - 🗂 Wasserzähler-Tausch mit Historie

        /// Speichert den aktuellen Wasserzähler als Historieeintrag und aktualisiert die Felder mit neuen Werten.
        func wasserzaehlerTauschen(zaehler: Wasserzaehler, wohnung: Wohnung,
                                   neuerAblesewertAlt: Double, neuerAblesewertNeu: Double,
                                   neuerFaktor: Double, grund: String) {
            let historie = WasserzaehlerHistorieEintrag(von: zaehler, grund: grund)
            modelContext.insert(historie)

            if zaehler.ablesewertAlt != neuerAblesewertAlt {
                logAenderung(bereich: "Wasserzähler", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Ablesewert Alt",
                             altWert: String(zaehler.ablesewertAlt), neuWert: String(neuerAblesewertAlt),
                             grund: grund)
            }
            if zaehler.ablesewertNeu != neuerAblesewertNeu {
                logAenderung(bereich: "Wasserzähler", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Ablesewert Neu",
                             altWert: String(zaehler.ablesewertNeu), neuWert: String(neuerAblesewertNeu),
                             grund: grund)
            }
            if zaehler.faktor != neuerFaktor {
                logAenderung(bereich: "Wasserzähler", wohnung: wohnung, zaehlernummer: zaehler.nummer,
                             feldname: "Faktor",
                             altWert: String(zaehler.faktor), neuWert: String(neuerFaktor),
                             grund: grund)
            }

            zaehler.ablesewertAlt = neuerAblesewertAlt
            zaehler.ablesewertNeu = neuerAblesewertNeu
            zaehler.faktor = neuerFaktor
            zaehler.datum = deKurzDatum(Date())
            try? modelContext.save()
        }
    
    // MARK: - Seed-Daten 2025 (1:1 aus Excel)

    private func clearExistingWEG(for jahr: Int) {
        do {
            var descriptor = FetchDescriptor<WEG>()
            descriptor.sortBy = [SortDescriptor(\.abrechnungsjahr)]
            let all = try modelContext.fetch(descriptor)
            let toDelete = all.filter { $0.abrechnungsjahr == jahr }
            for weg in toDelete {
                modelContext.delete(weg)
            }
            if !toDelete.isEmpty {
                try modelContext.save()
            }
        } catch {
            errorMessage = "Fehler beim Zurücksetzen der Seed-Daten: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func wiederherstellenJahr2025AusSeed() -> Bool {
        let bisherigesJahr = selectedJahr
        createSeedWEG2025()
        reload()

        if (try? modelContext.fetch(FetchDescriptor<WEG>()))?.contains(where: { $0.abrechnungsjahr == bisherigesJahr }) == true {
            jahresWechsel(zu: bisherigesJahr)
        } else {
            jahresWechsel(zu: 2025)
        }
        return weg?.abrechnungsjahr == bisherigesJahr || weg?.abrechnungsjahr == 2025
    }

    func createSeedWEG2025() {
        let seedYear = 2025
        selectedJahr = seedYear
        clearExistingWEG(for: seedYear)

        let seedWEG = WEG(
            name: "WEG Hausverwaltung 2025",
            adresse: "Import aus Gesamtabrechnung 2025",
            abrechnungsjahr: seedYear
        )

        // Hauptabrechnung 2025: feste Eingabewerte (werden dann per Formel verteilt)
        seedWEG.brennstoffverbrauchKwh = 39833
        seedWEG.faktorProKwhEuro = 0.09727838726683905
        seedWEG.verbrauchHeizungKwh = 32507.2
        seedWEG.verbrauchWarmwasserKwh = 7325.8
        seedWEG.gesamtwasserbetragLtRechnungEuro = 1817.65
        seedWEG.niederschlagswasserEuro = 95.38

        // Fixkosten 2025 (aus Zahlungen-Sheet)
        seedWEG.verguetungHmtEuro = 2400.00
        seedWEG.heizungWartungRepEuro = 404.76
        seedWEG.schornsteinfegerEuro = 99.81
        seedWEG.wartungBaurEuro = 304.95
        seedWEG.allgemeinStromEuro = 526.30
        seedWEG.muellGebuehrenEuro = 496.80
        seedWEG.muellGesamtPersonen = 10
        seedWEG.versicherungGebaeudeMitFeuerEuro = 1726.84
        seedWEG.versicherungHausHaftpflichtEuro = 60.45
        seedWEG.hausUndGrundEuro = 50.00
        seedWEG.nebenkostenGeldverkehrEuro = 172.95
        seedWEG.reparaturenAnschaffungenEuro = 0.00
        seedWEG.ruecklagenEuro = 6000.00
        seedWEG.kontoAktuellEuro = 34940.85

        let kostenarten = [
            Kostenart(name: "Hausgeld Soll (Jahr)", category: .nebenkosten),
            Kostenart(name: "Heizungsanteil 2025", category: .nebenkosten),
            Kostenart(name: "Wasseranteil 2025", category: .nebenkosten),
            Kostenart(name: "Warmwasser/sonstige Umlage", category: .sonstiges),
        ]
        for kostenart in kostenarten {
            seedWEG.kostenarten.append(kostenart)
            modelContext.insert(kostenart)
        }

        typealias SeedRow = (
            eigentuemer: String,
            wohnungsnummer: Int,
            flaeche: Double,
            personen: Int,
            heizungVerbrauch: Double,
            wasserVerbrauch: Double,
            sollHausgeld: Double,
            heizung30: Double,
            heizung70: Double,
            wasser30: Double,
            wasser70: Double,
            umlageSonstige: Double,
            gesamtWBlatt: Double,
            abweichungWBlatt: Double,
            hkv: [(nummer: String, bezeichnung: String, faktor: Double, ablesewertNeu: Double, verbrauchPunkte: Double)],
            wasser: [(nummer: String, art: WasserzaehlerArt, bezeichnung: String, alt: Double, neu: Double)]
        )

        let rows: [SeedRow] = [
                ("Becker", 107, 81.74, 2, 2694.034, 34.5, 3480.0, 187.07093801149955, 337.60010473722224, 72.31053204747849, 516.1619220385686, 390.92398784980014, 3593.0041513512356, -113.00415135123558,
                 [
                     ("90878776", "Bad", 1.717, 123, 211.191),
                     ("90878777", "Küche", 0.882, 0, 0),
                     ("90878834", "Kinderzimmer", 0.867, 219, 189.873),
                     ("90878779", "Kinderzimmer", 0.867, 81, 70.227),
                     ("90878835", "Wohnen", 2.289, 920, 2105.88),
                     ("90878786", "Wohnen", 1.717, 14, 24.038),
                     ("90878787", "Schlafen Kind", 1.175, 79, 92.825),
                     ("90878788", "Schlafzimmer", 1.782, 0, 0),
                 ],
                 [
                     ("36946744", .warmwasser, "Bad", 225, 259.5),
                     ("37425700", .kaltwasser, "Bad", 398.5, 464.72),
                     ("02235783", .waschkueche, "WK", 113, 123.25),
                 ]),
                ("Drost", 207, 58.77, 2, 3017.905, 2.0769999999999982, 2660.0, 134.50157850423085, 378.18566658289637, 51.99033482297910, 166.89707969564068, 23.534757181566206, 2695.00608345398, -35.006083453979954,
                 [
                     ("90878790", "Flur", 0.588, 0, 0),
                     ("90878791", "Wohnzimmer 1", 1.764, 995, 1755.18),
                     ("90878792", "Wohnzimmer 2", 1.175, 627, 736.725),
                     ("90878793", "Wohnzimmer 3", 1.175, 236, 277.3),
                     ("90878794", "Küche", 0.588, 0, 0),
                     ("90878795", "Bad", 1.23, 201, 247.23),
                     ("90878796", "Schlafzimmer", 1.47, 1, 1.47),
                 ],
                 [
                     ("37032658", .warmwasser, "Bad", 31.9, 33.977),
                     ("37425656", .kaltwasser, "Bad", 106.2, 124.322),
                     ("02234913", .waschkueche, "Waschmaschine", 10.4, 17.004),
                 ]),
                ("Bernsee", 307, 69.13, 3, 4982.496, 13.531999999999996, 3000.0, 158.21157260502770, 624.3763706964318, 61.15521263080729, 246.68719451737368, 153.33285227778242, 3183.65986939409, -183.65986939409004,
                 [
                     ("90878805", "Flur", 0.735, 0, 0),
                     ("90878806", "Bad", 1.717, 1818, 3121.506),
                     ("90878807", "Zimmer 1", 0.758, 0, 0),
                     ("90878808", "Zimmer 2", 0.758, 0, 0),
                     ("90878809", "Küche", 0.735, 0, 0),
                     ("90878810", "Wohnzimmer 1", 1.335, 1394, 1860.99),
                     ("90878811", "Wohnzimmer 2", 1.908, 0, 0),
                     ("90878812", "Schlafzimmer", 0.975, 0, 0),
                 ],
                 [
                     ("36946751", .warmwasser, "B", 65, 78.532),
                     ("37425639", .kaltwasser, "B", 160.7, 190.977),
                     ("02234948", .waschkueche, "WK", 61.2, 67.47),
                 ]),
                ("Ballestriero", 407, 73.87, 2, 3339.538, 8.381999999999998, 2520.0, 169.05958148898301, 418.4907757563318, 65.34840962010321, 183.62998677990385, 94.97753235237751, 2921.0829526643656, -401.08295266436562,
                 [
                     ("90878797", "Flur", 0.735, 1660, 1220.10),
                     ("90878798", "Zimmer 1", 1.273, 0, 0),
                     ("90878799", "Wohnzimmer 1", 2.016, 680, 1370.88),
                     ("90878800", "Wohnzimmer 2", 0.679, 0, 0),
                     ("90878801", "Wohnzimmer 3", 2.098, 142, 297.916),
                     ("90878802", "Küche", 0.954, 0, 0),
                     ("90878803", "Bad", 1.273, 354, 450.642),
                     ("90878804", "Schlafzimmer", 1.335, 0, 0),
                 ],
                 [
                     ("36946730", .warmwasser, "B", 41.2, 49.582),
                     ("37425693", .kaltwasser, "B", 150.4, 176.123),
                     ("02234937", .waschkueche, "WK", 12.5, 13.982),
                 ]),
                ("Weber", 507, 46.69, 2, 2095.92, 12.920999999999999, 2520.0, 106.85517611642909, 262.64806291265768, 41.30387498527980, 100.39744250557959, 146.4095317973121, 2597.5107549839249, -77.51075498392493,
                 [
                     ("90878819", "Flur", 0.735, 571, 419.685),
                     ("90878813", "Bad", 1.273, 1, 1.273),
                     ("90878814", "Küche", 0.954, 0, 0),
                     ("90878815", "Wohnzimmer 1", 3.055, 294, 898.17),
                     ("90878816", "Wohnzimmer 2", 1.029, 2, 2.058),
                     ("90878817", "Wohnzimmer 3", 2.098, 368, 772.064),
                     ("90878818", "Schlafzimmer", 1.335, 2, 2.67),
                 ],
                 [
                     ("36946720", .warmwasser, "Bad", 49.8, 62.721),
                     ("37425696", .kaltwasser, "Bad", 69.3, 82.474),
                     ("02235011", .waschkueche, "Waschmaschine", 9.2, 10.9),
                 ]),
                ("Gneiting", 607, 84.32, 4, 1534.3269999999998, 4.1000000000000014, 2640.0, 192.97555044200686, 192.27261270687299, 74.59290509228512, 94.18081990589975, 46.457633338671918, 2540.3761881524033, 99.6238118475967,
                 [
                     ("90878820", "Flur", 1.144, 0, 0),
                     ("90878821", "Küche", 0.954, 0, 0),
                     ("90878822", "Wohnzimmer 1", 1.029, 252, 259.308),
                     ("90878823", "Wohnzimmer 2", 1.335, 441, 588.735),
                     ("90878824", "Wohnzimmer 3", 1.335, 0, 0),
                     ("90878825", "Bad unten", 1.144, 6, 6.864),
                     ("90878826", "Handtuchhalter", 0.812, 27, 21.924),
                     ("90878827", "Arbeitszimmer", 1.144, 148, 169.312),
                     ("90878828", "Flur oben", 1.144, 145, 165.88),
                     ("90878829", "Schlafzimmer 1", 1.344, 85, 114.24),
                     ("90878830", "Schlafzimmer 2", 1.344, 148, 198.912),
                     ("90878831", "Bad oben", 1.144, 8, 9.152),
                 ],
                 [
                     ("60431048", .warmwasser, "B", 43.4, 46.994),
                     ("60573468", .warmwasser, "WC", 19, 19.506),
                     ("37425698", .kaltwasser, "B", 34.8, 36.831),
                     ("37425652", .kaltwasser, "WC", 435.4, 445.152),
                     ("02235773", .waschkueche, "WK", 50.1, 52.27),
                 ]),
        ]

        for row in rows {
            let wohnung = Wohnung(
                eigentuemer: row.eigentuemer,
                wohnungsnummer: row.wohnungsnummer,
                flaeche_qm: row.flaeche,
                personenanzahl: row.personen
            )

            wohnung.heizPunkteAnfang = 0
            wohnung.heizPunkteEnde = row.heizungVerbrauch
            wohnung.wasserWohnungZaehlerAnfang = 0
            wohnung.wasserWohnungZaehlerEnde = row.wasserVerbrauch
            wohnung.wasserWaschkuecheZaehlerAnfang = 0
            wohnung.wasserWaschkuecheZaehlerEnde = 0

            // Alt-Felder weiterhin befuellen fuer Kompatibilitaet mit bestehender Ansicht/Logik.
            wohnung.heizungJahresanfang = 0
            wohnung.heizungJahresende = row.heizungVerbrauch
            wohnung.wasserJahresanfang = 0
            wohnung.wasserJahresende = row.wasserVerbrauch

            for meter in row.hkv {
                let meta = hkvMetaByNummer[meter.nummer] ?? ("", "")
                let hkv = HeizkostenverteilerZaehler(
                    nummer: meter.nummer,
                    bezeichnung: meter.bezeichnung,
                    heizungstyp: meta.heizungstyp,
                    hinweis: meta.hinweis,
                    faktor: meter.faktor,
                    ablesewertNeu: meter.ablesewertNeu,
                    verbrauchPunkte: meter.verbrauchPunkte,
                    wohnung: wohnung
                )
                wohnung.heizkostenverteiler.append(hkv)
                modelContext.insert(hkv)
            }

            for meter in row.wasser {
                let w = Wasserzaehler(
                    nummer: meter.nummer,
                    art: meter.art,
                    bezeichnung: meter.bezeichnung,
                    typ: "Techem",
                    ablesewertAlt: meter.alt,
                    ablesewertNeu: meter.neu,
                    faktor: 1,
                    wohnung: wohnung
                )
                wohnung.wasserzaehler.append(w)
                modelContext.insert(w)
            }

            // Monatliche Vorauszahlungen (12 Monate, 1:1 aus Excel Zahlungen 2025)
            let monatsBetraege: [Int: Double]
            switch row.wohnungsnummer {
            case 107: // Becker: 290 alle 12 Monate
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 290.0) })
            case 207: // Drost: Jan–Apr 225, Mai–Dez 220
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, $0 <= 4 ? 225.0 : 220.0) })
            case 307: // Bernsee: 250 alle 12 Monate
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 250.0) })
            case 407: // Ballestriero: 210 alle 12 Monate
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 210.0) })
            case 507: // Weber: 210 alle 12 Monate
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 210.0) })
            case 607: // Gneiting: 220 alle 12 Monate
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 220.0) })
            default:
                monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, row.sollHausgeld / 12) })
            }
            for monat in 1...12 {
                let betrag = monatsBetraege[monat] ?? 0
                let zahlung = ZahlungsItem(kostenart: "Hausgeld", betrag: betrag, monat: monat)
                zahlung.wohnung = wohnung
                wohnung.zahlungen.append(zahlung)
                modelContext.insert(zahlung)
            }

            let ergebnis = AbrechnungsErgebnis(wohnung: wohnung)
            ergebnis.heizungAnteil30Prozent = row.heizung30
            ergebnis.heizungAnteil70Prozent = row.heizung70
            ergebnis.wasserAnteil30Prozent = row.wasser30
            ergebnis.wasserAnteil70Prozent = row.umlageSonstige  // WW70 war fälschlich in umlageSonstige
            ergebnis.kaltwasserGesamt = row.wasser70              // KW war fälschlich in wasser70
            ergebnis.sonstigeKosten = 0                           // wird vom Delta-Ausgleich gesetzt
            ergebnis.heizungGesamt = row.heizung30 + row.heizung70
            ergebnis.wasserGesamt = row.wasser30 + row.umlageSonstige
            ergebnis.zahlungsabweichung = row.abweichungWBlatt

            // W-Blatt-Gesamtwert wird über die bestehenden Felder abgebildet.
            let modellGesamt = ergebnis.gesamtgebuehr
            let delta = row.gesamtWBlatt - modellGesamt
            if abs(delta) > 0.000001 {
                ergebnis.sonstigeKosten += delta
            }

            wohnung.abrechnungsErgebnis = ergebnis

            seedWEG.wohnungen.append(wohnung)
            modelContext.insert(wohnung)
            modelContext.insert(ergebnis)
        }

        // Plausibler Startwert fuer Hauptwasserzaehler: Summe der Unterzaehler im Seed.
        seedWEG.hauptwasserZaehlerAnfang = 0
        seedWEG.hauptwasserZaehlerEnde = seedWEG.unterzaehlerGesamtverbrauch

        // Ausgaben 2025 (1:1 aus Sheet "Zahlungen 2025", Zeilen 30-41)
        // Einnahmen: HMT (200/Monat) und WEG Rücklagen (500/Monat) – Spalten I+J aus Excel
        for monat in 1...12 {
            let hmt = AusgabenItem(kategorie: "HMT", monat: monat, betrag: 200.0, weg: seedWEG)
            seedWEG.ausgaben.append(hmt)
            modelContext.insert(hmt)
            let rl = AusgabenItem(kategorie: "WEG Rücklagen", monat: monat, betrag: 500.0, weg: seedWEG)
            seedWEG.ausgaben.append(rl)
            modelContext.insert(rl)
        }

        let ausgabenRows: [(monat: Int, werte: [String: Double])] = [
            (1,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser": 442.07, "Haus und Grund": 50.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (2,  ["Strom VaFa": 97.3,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur": 304.95, "Auslagen HM": 0.0]),
            (3,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 44.65, "Müll": 496.8,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (4,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser": 160.66, "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (5,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (6,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 46.5,  "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (7,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein": 99.81, "Konto":  0.0,   "Müll":   0.0,   "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (8,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (9,  ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 40.9,  "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (10, ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (11, ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,   "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
            (12, ["Strom VaFa": 39.0,   "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 40.9,  "Müll":   0.0,   "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,   "Auslagen HM": 0.0]),
        ]

        for row in ausgabenRows {
            for (kategorie, betrag) in row.werte {
                let item = AusgabenItem(kategorie: kategorie, monat: row.monat, betrag: betrag, weg: seedWEG)
                seedWEG.ausgaben.append(item)
                modelContext.insert(item)
            }
        }

        modelContext.insert(seedWEG)
        self.weg = seedWEG

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Speichern der 2025-Seed-WEG: \(error.localizedDescription)"
        }
    }

    // Beibehaltung für bestehende UI-Aktionen
    func createTestWEG() {
        createSeedWEG2025()
    }

    // MARK: - Demo-/Musterjahr anlegen

    func createMusterjahr() {
        let musterYear = 2024
        selectedJahr = musterYear
        clearExistingWEG(for: musterYear)

        let musterWEG = WEG(
            name: "Musterhaus WEG",
            adresse: "Musterstraße 12, 72636 Musterstadt",
            abrechnungsjahr: musterYear
        )
        musterWEG.istMusterjahr = true

        // Gleiche Jahreswerte wie 2025 Seed (Demo-Daten)
        musterWEG.brennstoffverbrauchKwh = 39833
        musterWEG.faktorProKwhEuro = 0.09727838726683905
        musterWEG.verbrauchHeizungKwh = 32507.2
        musterWEG.verbrauchWarmwasserKwh = 7325.8
        musterWEG.gesamtwasserbetragLtRechnungEuro = 1817.65
        musterWEG.niederschlagswasserEuro = 95.38
        musterWEG.verguetungHmtEuro = 2400.00
        musterWEG.heizungWartungRepEuro = 404.76
        musterWEG.schornsteinfegerEuro = 99.81
        musterWEG.wartungBaurEuro = 304.95
        musterWEG.allgemeinStromEuro = 526.30
        musterWEG.muellGebuehrenEuro = 496.80
        musterWEG.muellGesamtPersonen = 10
        musterWEG.versicherungGebaeudeMitFeuerEuro = 1726.84
        musterWEG.versicherungHausHaftpflichtEuro = 60.45
        musterWEG.hausUndGrundEuro = 50.00
        musterWEG.nebenkostenGeldverkehrEuro = 172.95
        musterWEG.reparaturenAnschaffungenEuro = 0.00
        musterWEG.ruecklagenEuro = 6000.00
        musterWEG.kontoAktuellEuro = 34940.85
        musterWEG.abrechnungsHeaderTitel = "Demo-Abrechnung 2024"

        typealias SeedRow = (
            eigentuemer: String,
            wohnungsnummer: Int,
            flaeche: Double,
            personen: Int,
            heizungVerbrauch: Double,
            wasserVerbrauch: Double,
            sollHausgeld: Double,
            heizung30: Double,
            heizung70: Double,
            wasser30: Double,
            wasser70: Double,
            umlageSonstige: Double,
            gesamtWBlatt: Double,
            abweichungWBlatt: Double,
            hkv: [(nummer: String, bezeichnung: String, faktor: Double, ablesewertNeu: Double, verbrauchPunkte: Double)],
            wasser: [(nummer: String, art: WasserzaehlerArt, bezeichnung: String, alt: Double, neu: Double)]
        )

        let rows: [SeedRow] = [
            ("Müller", 101, 81.74, 2, 2694.034, 34.5, 3480.0, 187.07093801149955, 337.60010473722224, 72.31053204747849, 516.1619220385686, 390.92398784980014, 3593.0041513512356, -113.00415135123558,
             [
                 ("M0001", "Bad", 1.717, 123, 211.191),
                 ("M0002", "Küche", 0.882, 0, 0),
                 ("M0003", "Kinderzimmer", 0.867, 219, 189.873),
                 ("M0004", "Kinderzimmer", 0.867, 81, 70.227),
                 ("M0005", "Wohnen", 2.289, 920, 2105.88),
                 ("M0006", "Wohnen", 1.717, 14, 24.038),
                 ("M0007", "Schlafen Kind", 1.175, 79, 92.825),
                 ("M0008", "Schlafzimmer", 1.782, 0, 0),
             ],
             [
                 ("MW0001", .warmwasser, "Bad", 225, 259.5),
                 ("MW0002", .kaltwasser, "Bad", 398.5, 464.72),
                 ("MW0003", .waschkueche, "WK", 113, 123.25),
             ]),
            ("Schmidt", 201, 58.77, 2, 3017.905, 2.0769999999999982, 2660.0, 134.50157850423085, 378.18566658289637, 51.99033482297910, 166.89707969564068, 23.534757181566206, 2695.00608345398, -35.006083453979954,
             [
                 ("M0009", "Flur", 0.588, 0, 0),
                 ("M0010", "Wohnzimmer 1", 1.764, 995, 1755.18),
                 ("M0011", "Wohnzimmer 2", 1.175, 627, 736.725),
                 ("M0012", "Wohnzimmer 3", 1.175, 236, 277.3),
                 ("M0013", "Küche", 0.588, 0, 0),
                 ("M0014", "Bad", 1.23, 201, 247.23),
                 ("M0015", "Schlafzimmer", 1.47, 1, 1.47),
             ],
             [
                 ("MW0004", .warmwasser, "Bad", 31.9, 33.977),
                 ("MW0005", .kaltwasser, "Bad", 106.2, 124.322),
                 ("MW0006", .waschkueche, "Waschmaschine", 10.4, 17.004),
             ]),
            ("Meyer", 301, 69.13, 3, 4982.496, 13.531999999999996, 3000.0, 158.21157260502770, 624.3763706964318, 61.15521263080729, 246.68719451737368, 153.33285227778242, 3183.65986939409, -183.65986939409004,
             [
                 ("M0016", "Flur", 0.735, 0, 0),
                 ("M0017", "Bad", 1.717, 1818, 3121.506),
                 ("M0018", "Zimmer 1", 0.758, 0, 0),
                 ("M0019", "Zimmer 2", 0.758, 0, 0),
                 ("M0020", "Küche", 0.735, 0, 0),
                 ("M0021", "Wohnzimmer 1", 1.335, 1394, 1860.99),
                 ("M0022", "Wohnzimmer 2", 1.908, 0, 0),
                 ("M0023", "Schlafzimmer", 0.975, 0, 0),
             ],
             [
                 ("MW0007", .warmwasser, "B", 65, 78.532),
                 ("MW0008", .kaltwasser, "B", 160.7, 190.977),
                 ("MW0009", .waschkueche, "WK", 61.2, 67.47),
             ]),
            ("Fischer", 401, 73.87, 2, 2520.0, 8.381999999999998, 2520.0, 169.05958148898301, 418.4907757563318, 65.34840962010321, 183.62998677990385, 94.97753235237751, 2921.0829526643656, -401.08295266436562,
             [
                 ("M0024", "Flur", 0.735, 1660, 1220.10),
                 ("M0025", "Zimmer 1", 1.273, 0, 0),
                 ("M0026", "Wohnzimmer 1", 2.016, 680, 1370.88),
                 ("M0027", "Wohnzimmer 2", 0.679, 0, 0),
                 ("M0028", "Wohnzimmer 3", 2.098, 142, 297.916),
                 ("M0029", "Küche", 0.954, 0, 0),
                 ("M0030", "Bad", 1.273, 354, 450.642),
                 ("M0031", "Schlafzimmer", 1.335, 0, 0),
             ],
             [
                 ("MW0010", .warmwasser, "B", 41.2, 49.582),
                 ("MW0011", .kaltwasser, "B", 150.4, 176.123),
                 ("MW0012", .waschkueche, "WK", 12.5, 13.982),
             ]),
            ("Wagner", 501, 46.69, 2, 2520.0, 12.920999999999999, 2520.0, 106.85517611642909, 262.64806291265768, 41.30387498527980, 100.39744250557959, 146.4095317973121, 2597.5107549839249, -77.51075498392493,
             [
                 ("M0032", "Flur", 0.735, 571, 419.685),
                 ("M0033", "Bad", 1.273, 1, 1.273),
                 ("M0034", "Küche", 0.954, 0, 0),
                 ("M0035", "Wohnzimmer 1", 3.055, 294, 898.17),
                 ("M0036", "Wohnzimmer 2", 1.029, 2, 2.058),
                 ("M0037", "Wohnzimmer 3", 2.098, 368, 772.064),
                 ("M0038", "Schlafzimmer", 1.335, 2, 2.67),
             ],
             [
                 ("MW0013", .warmwasser, "Bad", 49.8, 62.721),
                 ("MW0014", .kaltwasser, "Bad", 69.3, 82.474),
                 ("MW0015", .waschkueche, "Waschmaschine", 9.2, 10.9),
             ]),
            ("Bauer", 601, 84.32, 4, 1534.3269999999998, 4.1000000000000014, 2640.0, 192.97555044200686, 192.27261270687299, 74.59290509228512, 94.18081990589975, 46.457633338671918, 2540.3761881524033, 99.6238118475967,
             [
                 ("M0039", "Flur", 1.144, 0, 0),
                 ("M0040", "Küche", 0.954, 0, 0),
                 ("M0041", "Wohnzimmer 1", 1.029, 252, 259.308),
                 ("M0042", "Wohnzimmer 2", 1.335, 441, 588.735),
                 ("M0043", "Wohnzimmer 3", 1.335, 0, 0),
                 ("M0044", "Bad unten", 1.144, 6, 6.864),
                 ("M0045", "Handtuchhalter", 0.812, 27, 21.924),
                 ("M0046", "Arbeitszimmer", 1.144, 148, 169.312),
                 ("M0047", "Flur oben", 1.144, 145, 165.88),
                 ("M0048", "Schlafzimmer 1", 1.344, 85, 114.24),
                 ("M0049", "Schlafzimmer 2", 1.344, 148, 198.912),
                 ("M0050", "Bad oben", 1.144, 8, 9.152),
             ],
             [
                 ("MW0016", .warmwasser, "B", 43.4, 46.994),
                 ("MW0017", .warmwasser, "WC", 19, 19.506),
                 ("MW0018", .kaltwasser, "B", 34.8, 36.831),
                 ("MW0019", .kaltwasser, "WC", 435.4, 445.152),
                 ("MW0020", .waschkueche, "WK", 50.1, 52.27),
             ]),
        ]

        for row in rows {
            let wohnung = Wohnung(
                eigentuemer: row.eigentuemer,
                wohnungsnummer: row.wohnungsnummer,
                flaeche_qm: row.flaeche,
                personenanzahl: row.personen
            )
            wohnung.heizPunkteAnfang = 0
            wohnung.heizPunkteEnde = row.heizungVerbrauch
            wohnung.wasserWohnungZaehlerAnfang = 0
            wohnung.wasserWohnungZaehlerEnde = row.wasserVerbrauch
            wohnung.wasserWaschkuecheZaehlerAnfang = 0
            wohnung.wasserWaschkuecheZaehlerEnde = 0
            wohnung.heizungJahresanfang = 0
            wohnung.heizungJahresende = row.heizungVerbrauch
            wohnung.wasserJahresanfang = 0
            wohnung.wasserJahresende = row.wasserVerbrauch

            for meter in row.hkv {
                let hkv = HeizkostenverteilerZaehler(
                    nummer: meter.nummer,
                    bezeichnung: meter.bezeichnung,
                    heizungstyp: "",
                    hinweis: "",
                    faktor: meter.faktor,
                    ablesewertNeu: meter.ablesewertNeu,
                    verbrauchPunkte: meter.verbrauchPunkte,
                    wohnung: wohnung
                )
                wohnung.heizkostenverteiler.append(hkv)
                modelContext.insert(hkv)
            }

            for meter in row.wasser {
                let w = Wasserzaehler(
                    nummer: meter.nummer,
                    art: meter.art,
                    bezeichnung: meter.bezeichnung,
                    typ: "Techem",
                    ablesewertAlt: meter.alt,
                    ablesewertNeu: meter.neu,
                    faktor: 1,
                    wohnung: wohnung
                )
                wohnung.wasserzaehler.append(w)
                modelContext.insert(w)
            }

            let monatsBetraege: [Int: Double]
            switch row.wohnungsnummer {
            case 101: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 290.0) })
            case 201: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, $0 <= 4 ? 225.0 : 220.0) })
            case 301: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 250.0) })
            case 401: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 210.0) })
            case 501: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 210.0) })
            case 601: monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 220.0) })
            default:  monatsBetraege = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, row.sollHausgeld / 12) })
            }
            for monat in 1...12 {
                let zahlung = ZahlungsItem(kostenart: "Hausgeld", betrag: monatsBetraege[monat] ?? 0, monat: monat)
                zahlung.wohnung = wohnung
                wohnung.zahlungen.append(zahlung)
                modelContext.insert(zahlung)
            }

            let ergebnis = AbrechnungsErgebnis(wohnung: wohnung)
            ergebnis.heizungAnteil30Prozent = row.heizung30
            ergebnis.heizungAnteil70Prozent = row.heizung70
            ergebnis.wasserAnteil30Prozent = row.wasser30
            ergebnis.wasserAnteil70Prozent = row.umlageSonstige
            ergebnis.kaltwasserGesamt = row.wasser70
            ergebnis.sonstigeKosten = 0
            ergebnis.heizungGesamt = row.heizung30 + row.heizung70
            ergebnis.wasserGesamt = row.wasser30 + row.umlageSonstige
            ergebnis.zahlungsabweichung = row.abweichungWBlatt
            let modellGesamt = ergebnis.gesamtgebuehr
            let delta = row.gesamtWBlatt - modellGesamt
            if abs(delta) > 0.000001 { ergebnis.sonstigeKosten += delta }
            wohnung.abrechnungsErgebnis = ergebnis

            musterWEG.wohnungen.append(wohnung)
            modelContext.insert(wohnung)
            modelContext.insert(ergebnis)
        }

        musterWEG.hauptwasserZaehlerAnfang = 0
        musterWEG.hauptwasserZaehlerEnde = musterWEG.unterzaehlerGesamtverbrauch

        for monat in 1...12 {
            let hmt = AusgabenItem(kategorie: "HMT", monat: monat, betrag: 200.0, weg: musterWEG)
            musterWEG.ausgaben.append(hmt)
            modelContext.insert(hmt)
            let rl = AusgabenItem(kategorie: "WEG Rücklagen", monat: monat, betrag: 500.0, weg: musterWEG)
            musterWEG.ausgaben.append(rl)
            modelContext.insert(rl)
        }

        let ausgabenRows: [(monat: Int, werte: [String: Double])] = [
            (1,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser": 442.07, "Haus und Grund": 50.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (2,  ["Strom VaFa": 97.3,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur": 304.95, "Auslagen HM": 0.0]),
            (3,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 44.65, "Müll": 496.8,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (4,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser": 160.66, "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (5,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (6,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 46.5,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (7,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein": 99.81, "Konto":  0.0,  "Müll":   0.0,  "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (8,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (9,  ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 40.9,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (10, ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser": 497.92, "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (11, ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto":  0.0,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
            (12, ["Strom VaFa": 39.0,  "fairenergie Gas": 290.0, "Schornstein":  0.0,  "Konto": 40.9,  "Müll":   0.0,  "Wasser":   0.0,  "Haus und Grund":  0.0, "Baur":   0.0,  "Auslagen HM": 0.0]),
        ]
        for row in ausgabenRows {
            for (kategorie, betrag) in row.werte {
                let item = AusgabenItem(kategorie: kategorie, monat: row.monat, betrag: betrag, weg: musterWEG)
                musterWEG.ausgaben.append(item)
                modelContext.insert(item)
            }
        }

        modelContext.insert(musterWEG)
        self.weg = musterWEG
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Speichern des Musterjahres: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Wohnung-Verwaltung
    
    func addWohnung(eigentuemer: String, wohnungsnummer: Int, flaeche: Double, personen: Int) {
        let newWohnung = Wohnung(
            eigentuemer: eigentuemer,
            wohnungsnummer: wohnungsnummer,
            flaeche_qm: flaeche,
            personenanzahl: personen
        )
        modelContext.insert(newWohnung)
        weg?.wohnungen.append(newWohnung)
        saveWEG()
    }
    
    func deleteWohnung(_ wohnung: Wohnung) {
        weg?.wohnungen.removeAll { $0.id == wohnung.id }
        modelContext.delete(wohnung)
        saveWEG()
    }

    // MARK: - Zählerverwaltung

    func addHKVZaehler(to wohnung: Wohnung) {
        let neuer = HeizkostenverteilerZaehler(
            nummer: "NEU-HKV",
            bezeichnung: "Neues Gerät",
            heizungstyp: "",
            hinweis: "",
            faktor: 1,
            ablesewertNeu: 0,
            verbrauchPunkte: 0,
            wohnung: wohnung
        )
        wohnung.heizkostenverteiler.append(neuer)
        modelContext.insert(neuer)
        saveWEG()
    }

    func removeHKVZaehler(from wohnung: Wohnung, zaehler: HeizkostenverteilerZaehler) {
        wohnung.heizkostenverteiler.removeAll { $0.id == zaehler.id }
        modelContext.delete(zaehler)
        saveWEG()
    }

    func addWasserzaehler(to wohnung: Wohnung, art: WasserzaehlerArt) {
        let neuer = Wasserzaehler(
            nummer: "NEU-WZ",
            art: art,
            bezeichnung: "Neues Gerät",
            typ: "Techem",
            ablesewertAlt: 0,
            ablesewertNeu: 0,
            faktor: 1,
            wohnung: wohnung
        )
        wohnung.wasserzaehler.append(neuer)
        modelContext.insert(neuer)
        saveWEG()
    }

    func removeWasserzaehler(from wohnung: Wohnung, zaehler: Wasserzaehler) {
        wohnung.wasserzaehler.removeAll { $0.id == zaehler.id }
        modelContext.delete(zaehler)
        saveWEG()
    }

    func synchronisiereWohnungsStammdaten(_ wohnung: Wohnung) {
        guard self.weg != nil else { return }
        let profile = eigentuemerProfileImAktuellenJahr()
        if let profil = profile.first(where: { $0.wohnungsnummer == wohnung.wohnungsnummer }) {
            profil.haushaltPersonen = max(1, wohnung.personenanzahl)
            profil.eigentumsanteilTausendstel = wohnung.eigentumsanteilTausendstel
            if wohnung.email?.isEmpty == false && (profil.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                profil.email = wohnung.email ?? profil.email
            }
        }
        saveWEG()
    }

    // MARK: - Ausgabenverwaltung

    func auslagenEintraege(fuer weg: WEG, monat: Int? = nil) -> [AuslagenEintrag] {
        let basis = weg.auslagenEintraege
        let gefiltert: [AuslagenEintrag]
        if let monat {
            gefiltert = basis.filter { $0.monat == monat }
        } else {
            gefiltert = basis
        }
        return gefiltert.sorted {
            if $0.monat == $1.monat {
                return $0.datum > $1.datum
            }
            return $0.monat < $1.monat
        }
    }

    func summeAuslagen(fuer weg: WEG, monat: Int) -> Double {
        let details = weg.auslagenEintraege.filter { $0.monat == monat }.reduce(0.0) { $0 + $1.betrag }
        let legacy = weg.ausgaben
            .filter { $0.kategorie == "Auslagen HM" && $0.monat == monat }
            .reduce(0.0) { $0 + $1.betrag }
        return details + legacy
    }

    func legacyAuslagenPositionen(fuer weg: WEG, monat: Int) -> [AusgabenItem] {
        weg.ausgaben
            .filter { $0.kategorie == "Auslagen HM" && $0.monat == monat }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    func addAuslagenEintrag(
        weg: WEG,
        monat: Int,
        betrag: Double,
        verwendungszweck: String,
        kaufort: String,
        datum: Date = Date()
    ) {
        let eintrag = AuslagenEintrag(
            monat: monat,
            betrag: betrag,
            verwendungszweck: verwendungszweck,
            kaufort: kaufort,
            datum: datum,
            weg: weg
        )
        weg.auslagenEintraege.append(eintrag)
        modelContext.insert(eintrag)
        synchronisiereFixkostenAusAusgaben(weg: weg, geaenderteKategorie: "Auslagen HM")
        saveWEG()
    }

    func deleteAuslagenEintrag(weg: WEG, eintrag: AuslagenEintrag) {
        if let idx = weg.auslagenEintraege.firstIndex(where: { $0.id == eintrag.id }) {
            weg.auslagenEintraege.remove(at: idx)
        }
        modelContext.delete(eintrag)
        synchronisiereFixkostenAusAusgaben(weg: weg, geaenderteKategorie: "Auslagen HM")
        saveWEG()
    }

    func updateAuslagenEintrag(
        weg: WEG,
        eintrag: AuslagenEintrag,
        betrag: Double,
        verwendungszweck: String,
        kaufort: String,
        datum: Date
    ) {
        eintrag.betrag = betrag
        eintrag.verwendungszweck = verwendungszweck
        eintrag.kaufort = kaufort
        eintrag.datum = datum
        synchronisiereFixkostenAusAusgaben(weg: weg, geaenderteKategorie: "Auslagen HM")
        saveWEG()
    }

    func deleteLegacyAuslagenPosition(weg: WEG, item: AusgabenItem) {
        if let idx = weg.ausgaben.firstIndex(where: { $0.id == item.id }) {
            weg.ausgaben.remove(at: idx)
        }
        modelContext.delete(item)
        synchronisiereFixkostenAusAusgaben(weg: weg, geaenderteKategorie: "Auslagen HM")
        saveWEG()
    }

    func ausgabenKategorien(fuer weg: WEG) -> [String] {
        var result: [String] = []
        for key in standardAusgabenKategorien where !result.contains(key) {
            result.append(key)
        }
        let raw = weg.ausgabenKategorienRaw
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        for key in raw where !result.contains(key) {
            result.append(key)
        }
        for item in weg.ausgaben {
            let key = item.kategorie.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty && !result.contains(key) {
                result.append(key)
            }
        }
        return result
    }

    private func speichereAusgabenKategorienRaw(weg: WEG) {
        weg.ausgabenKategorienRaw = ausgabenKategorien(fuer: weg)
            .joined(separator: "|")
    }

    @discardableResult
    func addAusgabenKategorie(weg: WEG, kategorie: String) -> Bool {
        let neu = kategorie.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !neu.isEmpty else { return false }
        let exists = ausgabenKategorien(fuer: weg).contains { $0.caseInsensitiveCompare(neu) == .orderedSame }
        guard !exists else { return false }
        stelleMonatsreiheSicher(weg: weg, kategorie: neu)
        speichereAusgabenKategorienRaw(weg: weg)
        saveWEG()
        return true
    }

    func setAusgabe(weg: WEG, monat: Int, kategorie: String, betrag: Double) {
        stelleMonatsreiheSicher(weg: weg, kategorie: kategorie)
        if let existing = weg.ausgaben.first(where: { $0.monat == monat && $0.kategorie == kategorie }) {
            existing.betrag = betrag
        } else {
            let item = AusgabenItem(kategorie: kategorie, monat: monat, betrag: betrag, weg: weg)
            weg.ausgaben.append(item)
            modelContext.insert(item)
        }
        speichereAusgabenKategorienRaw(weg: weg)
        synchronisiereFixkostenAusAusgaben(weg: weg, geaenderteKategorie: kategorie)
        saveWEG()
    }

    private func fallbackMonatswert(weg: WEG, kategorie: String) -> Double {
        switch kategorie {
        case "HMT": return weg.verguetungHmtEuro / 12
        case "WEG Rücklagen": return weg.ruecklagenEuro / 12
        case "Strom VaFa": return weg.allgemeinStromEuro / 12
        case "Gas", "fairenergie Gas":
            return weg.brennstoffverbrauchKwh > 0 ? (weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro) / 12 : 0
        case "Schornstein": return weg.schornsteinfegerEuro / 12
        case "Müll": return weg.muellGebuehrenEuro / 12
        case "Wasser": return weg.gesamtwasserbetragLtRechnungEuro / 12
        case "H&G", "Haus und Grund": return weg.hausUndGrundEuro / 12
        case "Baur": return weg.wartungBaurEuro / 12
        case "Auslagen HM": return weg.nebenkostenGeldverkehrEuro / 12
        default: return 0
        }
    }

    private func stelleMonatsreiheSicher(weg: WEG, kategorie: String) {
        let basis = fallbackMonatswert(weg: weg, kategorie: kategorie)
        for monat in 1...12 where !weg.ausgaben.contains(where: { $0.kategorie == kategorie && $0.monat == monat }) {
            let item = AusgabenItem(kategorie: kategorie, monat: monat, betrag: basis, weg: weg)
            weg.ausgaben.append(item)
            modelContext.insert(item)
        }
    }

    private func jahressumme(weg: WEG, kategorie: String) -> Double {
        weg.ausgaben
            .filter { $0.kategorie == kategorie && $0.monat >= 1 && $0.monat <= 12 }
            .reduce(0) { $0 + $1.betrag }
    }

    private func synchronisiereFixkostenAusAusgaben(weg: WEG, geaenderteKategorie: String) {
        switch geaenderteKategorie {
        case "HMT":
            weg.verguetungHmtEuro = jahressumme(weg: weg, kategorie: "HMT")
        case "WEG Rücklagen":
            weg.ruecklagenEuro = jahressumme(weg: weg, kategorie: "WEG Rücklagen")
        case "Strom VaFa":
            weg.allgemeinStromEuro = jahressumme(weg: weg, kategorie: "Strom VaFa")
        case "Gas", "fairenergie Gas":
            let jahresGas = jahressumme(weg: weg, kategorie: geaenderteKategorie)
            if weg.brennstoffverbrauchKwh > 0 {
                weg.faktorProKwhEuro = jahresGas / weg.brennstoffverbrauchKwh
            }
        case "Müll":
            weg.muellGebuehrenEuro = jahressumme(weg: weg, kategorie: "Müll")
        case "Schornstein":
            weg.schornsteinfegerEuro = jahressumme(weg: weg, kategorie: "Schornstein")
        case "Baur":
            weg.wartungBaurEuro = jahressumme(weg: weg, kategorie: "Baur")
        case "H&G", "Haus und Grund":
            weg.hausUndGrundEuro = jahressumme(weg: weg, kategorie: geaenderteKategorie)
        case "Auslagen HM":
            let legacy = jahressumme(weg: weg, kategorie: "Auslagen HM")
            let details = weg.auslagenEintraege
                .filter { $0.monat >= 1 && $0.monat <= 12 }
                .reduce(0.0) { $0 + $1.betrag }
            weg.nebenkostenGeldverkehrEuro = legacy + details
        case "Wasser":
            // Der Gemeinde-Rechnungswert wird in "Händische Eingaben" gepflegt
            // und darf nicht aus der Ausgaben-Tabelle ueberschrieben werden.
            break
        default:
            break
        }
    }
    
    // MARK: - Abrechnung berechnen
    
    func calculateAllAbrechnungen() {
        guard let weg = weg else { return }
        AbrechnungsService.berechneAbrechnung(weg: weg)
        saveWEG()
    }
    
    // MARK: - Hilfs-Properties
    
    var gesamtHeizung: Double {
        weg?.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch } ?? 0
    }

    var gesamtHeizPunkte: Double {
        gesamtHeizung
    }
    
    var gesamtWasser: Double {
        weg?.wohnungen.reduce(0) { $0 + $1.wasserVerbrauch } ?? 0
    }

    var gesamtWasserUnterzaehler: Double {
        gesamtWasser
    }

    var hauptwasserVerbrauch: Double {
        weg?.hauptwasserVerbrauch ?? 0
    }

    var wasserDifferenzHauptZuUnterzaehler: Double {
        weg?.wasserDifferenzHauptZuUnterzaehler ?? 0
    }
    
    var gesamtFlaeche: Double {
        weg?.wohnungen.reduce(0) { $0 + $1.flaeche_qm } ?? 0
    }
    
    var gesamtPersonen: Int {
        guard let weg else { return 0 }
        return AbrechnungsZeilenEngine.resolveHaushaltPersonenGesamt(
            in: weg,
            eigentuemerProfile: eigentuemerProfileImAktuellenJahr()
        )
    }
}
