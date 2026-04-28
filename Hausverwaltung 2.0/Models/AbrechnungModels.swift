import CryptoKit

// MARK: - 🔐 Admin-Einstellungen

/// Speichert den SHA-256-Hash des Admin-PINs. Nur ein Datensatz wird je App angelegt.
@Model final class AdminEinstellungen {
    var pinHash: String   // SHA-256 Hex-String
    var angelegtAm: Date = Date()

    init(pinHash: String) {
        self.pinHash = pinHash
    }

    /// Erzeugt einen SHA-256-Hash aus einem Klartext-PIN.
    static func hash(_ pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Prüft ob der eingegebene PIN korrekt ist.
    func verify(_ pin: String) -> Bool {
        AdminEinstellungen.hash(pin) == pinHash
    }
}

// MARK: - 📋 Änderungsprotokoll (Audit-Log)

/// Ein Eintrag im Änderungsprotokoll – wird bei jeder PIN-geschützten Änderung erstellt.
@Model final class AenderungsLog {
    var id: UUID = UUID()
    var datum: Date = Date()
    var bereich: String        // z.B. "HKV" oder "Wasserzähler"
    var wohnungsnummer: Int
    var eigentuemer: String
    var zaehlernummer: String
    var feldname: String       // z.B. "Faktor", "Ablesewert"
    var altWert: String
    var neuWert: String
    var grund: String

    init(bereich: String, wohnungsnummer: Int, eigentuemer: String,
         zaehlernummer: String, feldname: String,
         altWert: String, neuWert: String, grund: String) {
        self.bereich = bereich
        self.wohnungsnummer = wohnungsnummer
        self.eigentuemer = eigentuemer
        self.zaehlernummer = zaehlernummer
        self.feldname = feldname
        self.altWert = altWert
        self.neuWert = neuWert
        self.grund = grund
    }
}

// MARK: - 🗂 HKV-Historie

/// Historischer Snapshot eines HKV-Zählers vor einem Tausch oder einer Wertänderung.
@Model final class HKVHistorieEintrag {
    var id: UUID = UUID()
    var datum: Date = Date()
    var grund: String
    var nummer: String
    var bezeichnung: String
    var heizungstyp: String
    var faktor: Double
    var ablesewertNeu: Double
    var verbrauchPunkte: Double
    var wohnung: Wohnung?

    init(von zaehler: HeizkostenverteilerZaehler, grund: String) {
        self.grund = grund
        self.nummer = zaehler.nummer
        self.bezeichnung = zaehler.bezeichnung
        self.heizungstyp = zaehler.heizungstyp
        self.faktor = zaehler.faktor
        self.ablesewertNeu = zaehler.ablesewertNeu
        self.verbrauchPunkte = zaehler.verbrauchPunkte
        self.wohnung = zaehler.wohnung
    }
}

// MARK: - 🗂 Wasserzähler-Historie

/// Historischer Snapshot eines Wasserzählers vor einem Tausch oder einer Wertänderung.
@Model final class WasserzaehlerHistorieEintrag {
    var id: UUID = UUID()
    var datum: Date = Date()
    var grund: String
    var nummer: String
    var art: WasserzaehlerArt
    var bezeichnung: String
    var typ: String
    var ablesewertAlt: Double
    var ablesewertNeu: Double
    var faktor: Double
    var wohnung: Wohnung?

    init(von zaehler: Wasserzaehler, grund: String) {
        self.grund = grund
        self.nummer = zaehler.nummer
        self.art = zaehler.art
        self.bezeichnung = zaehler.bezeichnung
        self.typ = zaehler.typ
        self.ablesewertAlt = zaehler.ablesewertAlt
        self.ablesewertNeu = zaehler.ablesewertNeu
        self.faktor = zaehler.faktor
        self.wohnung = zaehler.wohnung
    }
}

// MARK: - 👤 Eigentümer-Stammdaten

/// Stammdaten je Eigentümer für die Hausverwaltung.
@Model final class EigentuemerProfil {
    var id: UUID = UUID()
    var abrechnungsjahr: Int
    var vorname: String
    var nachname: String

    var strasse: String
    var plz: String
    var ort: String

    /// Zugeordnete Wohnung aus dem vorhandenen Datenbestand (z. B. 107, 207, ...).
    var wohnungsnummer: Int?
    /// Eigentumsanteile in Tausendstel, typischerweise Summe aller Eigentümer = 1000.
    var eigentumsanteilTausendstel: Int
    // Legacy-Feld: optional halten, damit alte Stores nicht am Enum-Cast abstuerzen.
    var nutzungsart: EigentuemerNutzungsart? = nil
    // Migrationssicheres Speicherfeld.
    var nutzungsartRaw: String = EigentuemerNutzungsart.eigennutzung.rawValue
    var mieterName: String = ""
    var haushaltPersonen: Int = 1

    var geburtsdatum: Date?
    var notfallkontakt: String
    var notfallkontaktTelefon: String
    var telefon: String
    var email: String

    init(
        abrechnungsjahr: Int,
        vorname: String,
        nachname: String,
        strasse: String = "",
        plz: String = "",
        ort: String = "",
        wohnungsnummer: Int? = nil,
        eigentumsanteilTausendstel: Int = 0,
        nutzungsart: EigentuemerNutzungsart = .eigennutzung,
        mieterName: String = "",
        haushaltPersonen: Int = 1,
        geburtsdatum: Date? = nil,
        notfallkontakt: String = "",
        notfallkontaktTelefon: String = "",
        telefon: String = "",
        email: String = ""
    ) {
        self.abrechnungsjahr = abrechnungsjahr
        self.vorname = vorname
        self.nachname = nachname
        self.strasse = strasse
        self.plz = plz
        self.ort = ort
        self.wohnungsnummer = wohnungsnummer
        self.eigentumsanteilTausendstel = eigentumsanteilTausendstel
        self.nutzungsartRaw = nutzungsart.rawValue
        self.nutzungsart = nutzungsart
        self.mieterName = mieterName
        self.haushaltPersonen = max(1, haushaltPersonen)
        self.geburtsdatum = geburtsdatum
        self.notfallkontakt = notfallkontakt
        self.notfallkontaktTelefon = notfallkontaktTelefon
        self.telefon = telefon
        self.email = email
    }

    var vollerName: String {
        "\(vorname) \(nachname)".trimmingCharacters(in: .whitespaces)
    }

    var nutzungsartSicher: EigentuemerNutzungsart {
        if let art = EigentuemerNutzungsart(rawValue: nutzungsartRaw) {
            return art
        }
        if let legacy = nutzungsart {
            return legacy
        }
        return .eigennutzung
    }

    func setNutzungsart(_ art: EigentuemerNutzungsart) {
        nutzungsartRaw = art.rawValue
        nutzungsart = art
    }
}
//
//  AbrechnungModels.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftData
import Foundation

func deKurzDatum(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "de_DE")
    formatter.dateFormat = "dd.MM.yy"
    return formatter.string(from: date)
}

enum WasserzaehlerArt: String, Codable, CaseIterable {
    case warmwasser = "Warmwasser"
    case kaltwasser = "Kaltwasser"
    case waschkueche = "Waschkueche"
}

enum VerteilungsschluesselArt: String, Codable, CaseIterable {
    case wohneinheiten = "Wohneinheiten"
    case miteigentumsanteile = "Miteigentumsanteile"
    case personen = "Personen im Haushalt"
    case flaeche = "Wohnfläche (m²)"
    case verbrauch = "Verbrauch"

    var anzeigeName: String { rawValue }
}

enum EigentuemerNutzungsart: String, Codable, CaseIterable {
    case eigennutzung = "Eigennutzung"
    case vermietet = "Vermietet"

    var anzeigeName: String { rawValue }
}

enum HausverwalterArt: String, Codable, CaseIterable {
    case extern = "Extern"
    case eigentuemer = "Eigentümer"

    var anzeigeName: String { rawValue }
}

enum PDFSchriftGroesse: String, CaseIterable {
    case klein  = "klein"
    case mittel = "mittel"
    case gross  = "gross"

    var anzeigeName: String {
        switch self {
        case .klein:  return "Klein"
        case .mittel: return "Mittel"
        case .gross:  return "Groß"
        }
    }
    var faktor: CGFloat {
        switch self {
        case .klein:  return 0.85
        case .mittel: return 1.0
        case .gross:  return 1.18
        }
    }
}

enum PDFRandBreite: String, CaseIterable {
    case eng    = "eng"
    case normal = "normal"
    case weit   = "weit"

    var anzeigeName: String {
        switch self {
        case .eng:    return "Eng"
        case .normal: return "Normal"
        case .weit:   return "Weit"
        }
    }
    var punkte: CGFloat {
        switch self {
        case .eng:    return 28
        case .normal: return 46
        case .weit:   return 64
        }
    }
}

enum PDFHeaderFarbe: String, CaseIterable {
    case grau   = "grau"
    case blau   = "blau"
    case gruen  = "gruen"
    case dunkel = "dunkel"

    var anzeigeName: String {
        switch self {
        case .grau:   return "Grau"
        case .blau:   return "Blau"
        case .gruen:  return "Grün"
        case .dunkel: return "Dunkel"
        }
    }
}

enum AbrechnungsAnteilModell: String, Codable, CaseIterable {
    case proportional = "Proportional"
    case direkterBetrag = "Direktbetrag"

    var anzeigeName: String { rawValue }
}

enum AbrechnungsWertQuelle: String, Codable, CaseIterable {
    case none = "none"
    case constantOne = "constant_one"
    case wohnungsanzahl = "wohnungsanzahl"
    case verguetungHmtEuro = "verguetung_hmt"
    case heizkostenBrennstoffEuro = "heizkosten_brennstoff"
    case gesamtwasserbetragLtRechnungEuro = "gesamtwasserbetrag_rechnung"
    case schornsteinfegerEuro = "schornsteinfeger"
    case wartungBaurEuro = "wartung_baur"
    case allgemeinStromEuro = "allgemein_strom"
    case muellGebuehrenEuro = "muell_gebuehren"
    case muellGesamtPersonen = "muell_gesamt_personen"
    case wohnungPersonen = "wohnung_personen"
    case versicherungGebaeudeMitFeuerEuro = "versicherung_gebaeude_mit_feuer"
    case versicherungHausHaftpflichtEuro = "versicherung_haus_haftpflicht"
    case hausUndGrundEuro = "haus_und_grund"
    case nebenkostenGeldverkehrEuro = "nebenkosten_geldverkehr"
    case reparaturenAnschaffungenEuro = "reparaturen_anschaffungen"
    case ruecklagenEuro = "ruecklagen"
    case wohnflaecheGesamt = "wohnflaeche_gesamt"
    case wohnflaecheWohnung = "wohnflaeche_wohnung"
    case heizungVerbrauchGesamt = "heizung_verbrauch_gesamt"
    case heizungVerbrauchWohnung = "heizung_verbrauch_wohnung"
    case miteigentumsanteileGesamt = "miteigentumsanteile_gesamt"
    case miteigentumsanteileWohnung = "miteigentumsanteile_wohnung"
    case haushaltPersonenGesamt = "haushalt_personen_gesamt"
    case haushaltPersonenWohnung = "haushalt_personen_wohnung"
    case heizungVerbrauchAnteil = "heizung_verbrauch_anteil"

    var anzeigeName: String {
        switch self {
        case .none: return "Kein Wert"
        case .constantOne: return "Konstante 1"
        case .wohnungsanzahl: return "Anzahl Wohnungen"
        case .verguetungHmtEuro: return "Vergütung Techn. Hausbetr."
        case .heizkostenBrennstoffEuro: return "Heizkosten Brennstoff"
        case .gesamtwasserbetragLtRechnungEuro: return "Gesamtwasserbetrag laut Rechnung"
        case .schornsteinfegerEuro: return "Schornsteinfeger"
        case .wartungBaurEuro: return "Wartung Baur"
        case .allgemeinStromEuro: return "Allgemein Strom"
        case .muellGebuehrenEuro: return "Müllgebühren"
        case .muellGesamtPersonen: return "Gesamtpersonen Müll"
        case .wohnungPersonen: return "Personen Wohnung"
        case .versicherungGebaeudeMitFeuerEuro: return "Versicherung Gebäude mit Feuer"
        case .versicherungHausHaftpflichtEuro: return "Versicherung Haus-Haftpflicht"
        case .hausUndGrundEuro: return "Haus & Grund"
        case .nebenkostenGeldverkehrEuro: return "Nebenkosten Geldverkehr"
        case .reparaturenAnschaffungenEuro: return "Reparaturen/Anschaffungen"
        case .ruecklagenEuro: return "Rücklagen"
        case .wohnflaecheGesamt: return "Gesamtfläche"
        case .wohnflaecheWohnung: return "Wohnfläche Wohnung"
        case .heizungVerbrauchGesamt: return "Heizverbrauch gesamt"
        case .heizungVerbrauchWohnung: return "Heizverbrauch Wohnung"
        case .miteigentumsanteileGesamt: return "Miteigentumsanteile gesamt"
        case .miteigentumsanteileWohnung: return "Miteigentumsanteil Wohnung"
        case .haushaltPersonenGesamt: return "Haushaltspersonen gesamt"
        case .haushaltPersonenWohnung: return "Haushaltspersonen Wohnung"
        case .heizungVerbrauchAnteil: return "Heizung Verbrauchsanteil Wohnung"
        }
    }
}

@Model final class AbrechnungsZeileKonfiguration {
    var id: UUID = UUID()
    var abrechnungsjahr: Int
    var name: String
    var gesamtbetragEuro: Double
    var schluesselArt: VerteilungsschluesselArt
    var istGlobal: Bool
    var wohnungsnummer: Int?
    var gesamtSchluesselManuell: Double
    var wohnungsSchluesselManuell: Double
    var sortierung: Int
    var aktiv: Bool
    var systemCode: String = ""
    var istStandard: Bool = false
    var betragQuellenRaw: String = ""
    var schluesselGesamtQuelleRaw: String = AbrechnungsWertQuelle.none.rawValue
    var schluesselWertQuelleRaw: String = AbrechnungsWertQuelle.none.rawValue
    var wohnungsBetragQuelleRaw: String = AbrechnungsWertQuelle.none.rawValue
    var schluesselBezeichnungOverride: String = ""
    var anteilsModellRaw: String = AbrechnungsAnteilModell.proportional.rawValue
    /// Speichert pro Wohnung einen manuellen Umlageschlüssel.
    /// Format: "wohnungsnummer:wert|wohnungsnummer:wert|..."
    var wohnungsSchluesselManuellMapRaw: String = ""

    init(
        abrechnungsjahr: Int,
        name: String,
        gesamtbetragEuro: Double,
        schluesselArt: VerteilungsschluesselArt,
        istGlobal: Bool,
        wohnungsnummer: Int? = nil,
        gesamtSchluesselManuell: Double = 0,
        wohnungsSchluesselManuell: Double = 0,
        sortierung: Int = 0,
        aktiv: Bool = true
    ) {
        self.abrechnungsjahr = abrechnungsjahr
        self.name = name
        self.gesamtbetragEuro = gesamtbetragEuro
        self.schluesselArt = schluesselArt
        self.istGlobal = istGlobal
        self.wohnungsnummer = wohnungsnummer
        self.gesamtSchluesselManuell = gesamtSchluesselManuell
        self.wohnungsSchluesselManuell = wohnungsSchluesselManuell
        self.sortierung = sortierung
        self.aktiv = aktiv
    }

    var betragQuellen: [AbrechnungsWertQuelle] {
        betragQuellenRaw
            .split(separator: "|")
            .compactMap { AbrechnungsWertQuelle(rawValue: String($0)) }
    }

    var schluesselGesamtQuelleSicher: AbrechnungsWertQuelle {
        AbrechnungsWertQuelle(rawValue: schluesselGesamtQuelleRaw) ?? .none
    }

    var schluesselWertQuelleSicher: AbrechnungsWertQuelle {
        AbrechnungsWertQuelle(rawValue: schluesselWertQuelleRaw) ?? .none
    }

    var wohnungsBetragQuelleSicher: AbrechnungsWertQuelle {
        AbrechnungsWertQuelle(rawValue: wohnungsBetragQuelleRaw) ?? .none
    }

    var anteilsModellSicher: AbrechnungsAnteilModell {
        AbrechnungsAnteilModell(rawValue: anteilsModellRaw) ?? .proportional
    }

    var schluesselBezeichnungAnzeige: String {
        let text = schluesselBezeichnungOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? schluesselArt.anzeigeName : text
    }

    // MARK: - Per-Wohnung Umlageschlüssel

    /// Gibt den manuell gesetzten Umlageschlüssel für eine Wohnung zurück,
    /// oder nil wenn kein manueller Wert gesetzt ist.
    var wohnungsSchluesselManuellMap: [Int: Double] {
        var map: [Int: Double] = [:]
        for eintrag in wohnungsSchluesselManuellMapRaw.split(separator: "|") {
            let teile = eintrag.split(separator: ":")
            if teile.count == 2,
               let nr = Int(teile[0]),
               let wert = Double(teile[1]),
               wert > 0 {
                map[nr] = wert
            }
        }
        return map
    }

    func wohnungsSchluessel(fuer wohnungsnummer: Int) -> Double? {
        wohnungsSchluesselManuellMap[wohnungsnummer]
    }

    /// Setzt oder löscht (wert <= 0) den manuellen Umlageschlüssel für eine Wohnung.
    func setWohnungsSchluessel(fuer wohnungsnummer: Int, wert: Double) {
        var map = wohnungsSchluesselManuellMap
        if wert > 0 {
            map[wohnungsnummer] = wert
        } else {
            map.removeValue(forKey: wohnungsnummer)
        }
        wohnungsSchluesselManuellMapRaw = map.sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "|")
    }

    var quellenBeschreibung: String {
        let quellen = betragQuellen.map(\ .anzeigeName)
        return quellen.isEmpty ? "Manueller Betrag" : quellen.joined(separator: " + ")
    }

    var nutztAutomatischeQuellen: Bool {
        !betragQuellen.isEmpty || anteilsModellSicher == .direkterBetrag
    }

    func setBetragQuellen(_ quellen: [AbrechnungsWertQuelle]) {
        betragQuellenRaw = quellen.map(\ .rawValue).joined(separator: "|")
    }

    func setSchluesselGesamtQuelle(_ quelle: AbrechnungsWertQuelle) {
        schluesselGesamtQuelleRaw = quelle.rawValue
    }

    func setSchluesselWertQuelle(_ quelle: AbrechnungsWertQuelle) {
        schluesselWertQuelleRaw = quelle.rawValue
    }

    func setWohnungsBetragQuelle(_ quelle: AbrechnungsWertQuelle) {
        wohnungsBetragQuelleRaw = quelle.rawValue
    }

    func setAnteilsModell(_ modell: AbrechnungsAnteilModell) {
        anteilsModellRaw = modell.rawValue
    }
}

@Model final class HeizkostenverteilerZaehler {
    var id: UUID = UUID()
    var nummer: String
    var bezeichnung: String
    var heizungstyp: String
    var hinweis: String
    var datum: String
    var faktor: Double
    var ablesewertNeu: Double
    var verbrauchPunkte: Double
    var wohnung: Wohnung?

    init(
        nummer: String,
        bezeichnung: String,
        heizungstyp: String,
        hinweis: String = "",
        datum: String = "",
        faktor: Double,
        ablesewertNeu: Double,
        verbrauchPunkte: Double,
        wohnung: Wohnung? = nil
    ) {
        self.nummer = nummer
        self.bezeichnung = bezeichnung
        self.heizungstyp = heizungstyp
        self.hinweis = hinweis
        self.datum = datum
        self.faktor = faktor
        self.ablesewertNeu = ablesewertNeu
        self.verbrauchPunkte = verbrauchPunkte
        self.wohnung = wohnung
    }
}

@Model final class Wasserzaehler {
    var id: UUID = UUID()
    var nummer: String
    var art: WasserzaehlerArt
    var bezeichnung: String
    var typ: String
    var datum: String
    var ablesewertAlt: Double
    var ablesewertNeu: Double
    var faktor: Double
    var wohnung: Wohnung?

    var verbrauch: Double {
        max(0, (ablesewertNeu - ablesewertAlt) * faktor)
    }

    init(
        nummer: String,
        art: WasserzaehlerArt,
        bezeichnung: String,
        typ: String = "",
        datum: String = "",
        ablesewertAlt: Double,
        ablesewertNeu: Double,
        faktor: Double = 1,
        wohnung: Wohnung? = nil
    ) {
        self.nummer = nummer
        self.art = art
        self.bezeichnung = bezeichnung
        self.typ = typ
        self.datum = datum
        self.ablesewertAlt = ablesewertAlt
        self.ablesewertNeu = ablesewertNeu
        self.faktor = faktor
        self.wohnung = wohnung
    }
}

// MARK: - 📊 Basis-Modelle für WEG-Abrechnung

/// Das Abrechnungsjahr (2024, 2025, etc.)
@Model final class AbrechnungsJahr {
    var jahr: Int
    var weg: WEG?
    var erstelltAm: Date = Date()
    var aktualisiertAm: Date = Date()
    
    init(jahr: Int) {
        self.jahr = jahr
    }
}

/// Die Wohneinheit-Gemeinschaft (WEG) mit 1-8 Wohnungen
@Model final class WEG {
    var id: UUID = UUID()
    var name: String
    var adresse: String
    var wohnungen: [Wohnung] = []
    var abrechnungsjahr: Int
    var kostenarten: [Kostenart] = []
    var ausgaben: [AusgabenItem] = []
    var auslagenEintraege: [AuslagenEintrag] = []
    var ausgabenKategorienRaw: String = ""

    // Hauptabrechnung: feste Eingabewerte
    var brennstoffverbrauchKwh: Double = 0
    var faktorProKwhEuro: Double = 0
    var verbrauchHeizungKwh: Double = 0
    var verbrauchWarmwasserKwh: Double = 0
    var gesamtwasserbetragLtRechnungEuro: Double = 0
    var niederschlagswasserEuro: Double = 0

    // Fixkosten (editierbar in Einstellungen)
    var verguetungHmtEuro: Double = 2400.00
    var heizungWartungRepEuro: Double = 404.76
    var schornsteinfegerEuro: Double = 99.81          // Unterzeile von heizungWartungRepEuro
    var wartungBaurEuro: Double = 304.95              // Unterzeile von heizungWartungRepEuro
    var allgemeinStromEuro: Double = 526.30
    var muellGebuehrenEuro: Double = 496.80
    var muellGesamtPersonen: Int = 10
    var versicherungGebaeudeMitFeuerEuro: Double = 1726.84
    var versicherungHausHaftpflichtEuro: Double = 60.45
    var hausUndGrundEuro: Double = 50.00
    var nebenkostenGeldverkehrEuro: Double = 172.95
    var reparaturenAnschaffungenEuro: Double = 0.00
    var ruecklagenEuro: Double = 6000.00
    var kontoAktuellEuro: Double = 34940.85

    // Computed
    var versicherungenGesamtEuro: Double { versicherungGebaeudeMitFeuerEuro + versicherungHausHaftpflichtEuro }

    // Hauptzähler Wasser (Keller)
    var hauptwasserZaehlerAnfang: Double = 0
    var hauptwasserZaehlerEnde: Double = 0

    // Jahresabschluss
    var abgeschlossen: Bool = false
    var abgeschlossenAm: Date? = nil

    // Musterjahr-Flag (Demo-Daten für erste App-Nutzung)
    var istMusterjahr: Bool = false

    // Globaler Abrechnungsheader (für alle Wohnungen)
    var abrechnungsHeaderTitel: String = ""
    var abrechnungsHeaderUntertitel: String = ""
    // Mehrzeilig: jede Zeile = ein Punkt
    var abrechnungsHeaderPunkteText: String = ""
    // Altfeld (Legacy) bleibt bestehen, um alte Daten nicht zu verlieren.
    var standardVerteilungsschluessel: VerteilungsschluesselArt? = nil
    // Neues, migrationssicheres Speicherfeld.
    var standardVerteilungsschluesselRaw: String = VerteilungsschluesselArt.wohneinheiten.rawValue

    // WEG-Verwaltung
    var hausverwalterName: String = ""
    var hausverwalterStrasse: String = ""
    var hausverwalterPlz: String = ""
    var hausverwalterOrt: String = ""
    var hausverwalterTelefon: String = ""
    var hausverwalterEmail: String = ""
    var hausverwalterArtRaw: String = HausverwalterArt.extern.rawValue
    var hausverwalterGewaehltAm: Date = Date()

    // Abrechnungszeitraum
    var abrechnungszeitraumVon: Date = Date()
    var abrechnungszeitraumBis: Date = Date()

    // Optionales WEG-Logo (PNG/JPEG Daten)
    var wegLogoBildData: Data = Data()

    // PDF-Layout
    var pdfSchriftGroesseRaw: String = PDFSchriftGroesse.mittel.rawValue
    var pdfRandBreiteRaw: String     = PDFRandBreite.normal.rawValue
    var pdfHeaderFarbeRaw: String    = PDFHeaderFarbe.grau.rawValue
    var pdfFusszeileEinblenden: Bool = true

    // PDF-Layout: Logo & Abstände
    var pdfLogoPositionRaw: String = "links"   // links | mitte | rechts
    var pdfLogoHoehePt: Double     = 44        // Höhe in PDF-Punkten
    var pdfLogoSkalierung: Double  = 1.0       // 0.5 ... 2.0
    var pdfLogoOffsetY: Double     = 0         // vertikale Verschiebung
    var pdfTitelAbstandOben: Double = 14       // Abstand nach dem Briefkopf
    var pdfTabellenStartOffsetY: Double = 0    // Tabelle nach unten/oben

    // PDF-Layout: Kopfzeile & Fußzeile (editierbare Texte)
    var pdfKopfzeileText: String   = "Hausverwaltung Thomas Becker, Uhlandstr. 12, 72636 Frickenhausen"
    var pdfKopfzeileOffsetY: Double = 0
    var pdfAdresseOffsetX: Double = 0
    var pdfAdresseOffsetY: Double = 0
    var pdfFusszeile1Text: String  = "Bankverbindung: KSK Esslingen IBAN DE70 6115 0020 0008 1610 37"
    var pdfFusszeile2Text: String  = "weg.uhlandstr.12@gmx.de"
    var pdfFusszeile1OffsetY: Double = 0
    var pdfFusszeile2OffsetY: Double = 0

    init(name: String, adresse: String, abrechnungsjahr: Int) {
        self.name = name
        self.adresse = adresse
        self.abrechnungsjahr = abrechnungsjahr

        let calendar = Calendar.current
        self.abrechnungszeitraumVon = calendar.date(from: DateComponents(year: abrechnungsjahr, month: 1, day: 1)) ?? Date()
        self.abrechnungszeitraumBis = calendar.date(from: DateComponents(year: abrechnungsjahr, month: 12, day: 31)) ?? Date()
    }

    var abrechnungsTitelAnzeige: String {
        let titel = abrechnungsHeaderTitel.trimmingCharacters(in: .whitespacesAndNewlines)
        return titel.isEmpty ? "Abrechnung \(abrechnungsjahr)" : titel
    }

    var abrechnungsUntertitelAnzeige: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy"
        let von = formatter.string(from: abrechnungszeitraumVon)
        let bis = formatter.string(from: abrechnungszeitraumBis)
        let standard = "Abrechnung vom \(von) bis \(bis)"
        let subtitel = abrechnungsHeaderUntertitel.trimmingCharacters(in: .whitespacesAndNewlines)
        return subtitel.isEmpty ? standard : subtitel
    }

    var abrechnungsHeaderPunkte: [String] {
        abrechnungsHeaderPunkteText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var standardVerteilungsschluesselSicher: VerteilungsschluesselArt {
        if let art = VerteilungsschluesselArt(rawValue: standardVerteilungsschluesselRaw) {
            return art
        }
        if let legacy = standardVerteilungsschluessel {
            return legacy
        }
        return VerteilungsschluesselArt.wohneinheiten
    }

    func setStandardVerteilungsschluessel(_ art: VerteilungsschluesselArt) {
        standardVerteilungsschluesselRaw = art.rawValue
        standardVerteilungsschluessel = art
    }

    var hausverwalterArtSicher: HausverwalterArt {
        HausverwalterArt(rawValue: hausverwalterArtRaw) ?? .extern
    }

    func setHausverwalterArt(_ art: HausverwalterArt) {
        hausverwalterArtRaw = art.rawValue
    }

    var hausverwalterAmtsende: Date {
        Calendar.current.date(byAdding: .year, value: 5, to: hausverwalterGewaehltAm) ?? hausverwalterGewaehltAm
    }
    
    /// Alle Wohnungen nach Nummer sortiert
    var wohnungenSortiert: [Wohnung] {
        wohnungen.sorted { $0.wohnungsnummer < $1.wohnungsnummer }
    }

    var hauptwasserVerbrauch: Double {
        max(0, hauptwasserZaehlerEnde - hauptwasserZaehlerAnfang)
    }

    var unterzaehlerGesamtverbrauch: Double {
        wohnungen.reduce(0) { $0 + $1.wasserVerbrauch }
    }

    var wasserDifferenzHauptZuUnterzaehler: Double {
        hauptwasserVerbrauch - unterzaehlerGesamtverbrauch
    }

    // Hauptabrechnung: Formelwerte (wie in Excel)
    var heizkostenBrennstoffEuro: Double {
        faktorProKwhEuro * verbrauchHeizungKwh
    }

    var warmwasserBrennstoffEuro: Double {
        faktorProKwhEuro * verbrauchWarmwasserKwh
    }

    var warmwasserMengeM3: Double {
        wohnungen.reduce(0) { $0 + $1.warmwasserVerbrauch }
    }

    var kaltwasserMengeM3: Double {
        wohnungen.reduce(0) { $0 + $1.kaltwasserVerbrauch }
    }

    var gesamtwasserMengeM3: Double {
        warmwasserMengeM3 + kaltwasserMengeM3
    }

    var wasserbetragOhneNiederschlagEuro: Double {
        if abrechnungsjahr >= 2026 {
            return max(0, gesamtwasserbetragLtRechnungEuro - niederschlagswasserEuro)
        }
        return gesamtwasserbetragLtRechnungEuro
    }

    var kaltwasserAnteilFuerWarmwasserEuro: Double {
        guard gesamtwasserMengeM3 > 0 else { return 0 }
        // Ab 2026 basiert die m³-Verteilung auf dem Wasserbetrag ohne Niederschlagswasser.
        return wasserbetragOhneNiederschlagEuro * (warmwasserMengeM3 / gesamtwasserMengeM3)
    }

    var warmwasserkostenGesamtEuro: Double {
        warmwasserBrennstoffEuro + kaltwasserAnteilFuerWarmwasserEuro
    }

    var heizkostenGesamtEuro: Double {
        heizkostenBrennstoffEuro + warmwasserkostenGesamtEuro
    }

    var kaltwasserkostenVerbrauchsanteilEuro: Double {
        max(0, wasserbetragOhneNiederschlagEuro - kaltwasserAnteilFuerWarmwasserEuro)
    }

    var niederschlagswasserPauschalEuro: Double {
        abrechnungsjahr >= 2026 ? max(0, niederschlagswasserEuro) : 0
    }

    var kaltwasserkostenGesamtEuro: Double {
        // Ab 2026: Niederschlagswasser wird separat pauschal auf 6 Wohnungen verteilt.
        kaltwasserkostenVerbrauchsanteilEuro + niederschlagswasserPauschalEuro
    }

    var gesamtkostenHeizungWasserEuro: Double {
        heizkostenGesamtEuro + kaltwasserkostenGesamtEuro
    }

    var ausgabenGesamtEuro: Double {
        ausgaben.reduce(0) { $0 + $1.betrag }
    }
}

/// Eine einzelne Wohnung (1-8)
@Model final class Wohnung {
    var id: UUID = UUID()
    var eigentuemer: String
    var wohnungsnummer: Int  // z.B. 107, 207, 307, ...
    var flaeche_qm: Double
    var personenanzahl: Int
    var eigentumsanteilTausendstel: Int = 0
    var email: String?
    
    // Alt-Felder (Bestandskompatibilitaet)
    var heizungJahresanfang: Double = 0
    var heizungJahresende: Double = 0
    var wasserJahresanfang: Double = 0
    var wasserJahresende: Double = 0

    // Messwerte Heizung: Punkte der Heizkostenverteiler
    var heizPunkteAnfang: Double = 0
    var heizPunkteEnde: Double = 0

    // Einzelzaehler mit Nummern (aus Excel)
    var heizkostenverteiler: [HeizkostenverteilerZaehler] = []
    var wasserzaehler: [Wasserzaehler] = []

    // Messwerte Wasser: Unterzaehler je Wohnung + Waschkueche
    var wasserWohnungZaehlerAnfang: Double = 0
    var wasserWohnungZaehlerEnde: Double = 0
    var wasserWaschkuecheZaehlerAnfang: Double = 0
    var wasserWaschkuecheZaehlerEnde: Double = 0
    
    // Zahlungen (variabel pro Kostenart)
    var zahlungen: [ZahlungsItem] = []
    
    // Berechnete Abrechnung
    var abrechnungsErgebnis: AbrechnungsErgebnis?
    
    init(eigentuemer: String, wohnungsnummer: Int, flaeche_qm: Double, personenanzahl: Int, eigentumsanteilTausendstel: Int = 0) {
        self.eigentuemer = eigentuemer
        self.wohnungsnummer = wohnungsnummer
        self.flaeche_qm = flaeche_qm
        self.personenanzahl = personenanzahl
        self.eigentumsanteilTausendstel = eigentumsanteilTausendstel
    }
    
    // MARK: - Berechnete Properties
    
    var heizungVerbrauch: Double {
        if !heizkostenverteiler.isEmpty {
            return heizkostenverteiler.reduce(0) { $0 + $1.verbrauchPunkte }
        }
        let heizPunkte = max(0, heizPunkteEnde - heizPunkteAnfang)
        if heizPunkteAnfang != 0 || heizPunkteEnde != 0 {
            return heizPunkte
        }
        return max(0, heizungJahresende - heizungJahresanfang)
    }
    
    var wasserVerbrauch: Double {
        if !wasserzaehler.isEmpty {
            return wasserzaehler.reduce(0) { $0 + $1.verbrauch }
        }
        let wohnung = max(0, wasserWohnungZaehlerEnde - wasserWohnungZaehlerAnfang)
        let waschkueche = max(0, wasserWaschkuecheZaehlerEnde - wasserWaschkuecheZaehlerAnfang)
        if wasserWohnungZaehlerAnfang != 0 || wasserWohnungZaehlerEnde != 0 || wasserWaschkuecheZaehlerAnfang != 0 || wasserWaschkuecheZaehlerEnde != 0 {
            return wohnung + waschkueche
        }
        return max(0, wasserJahresende - wasserJahresanfang)
    }

    var wasserWohnungVerbrauch: Double {
        if !wasserzaehler.isEmpty {
            return wasserzaehler
                .filter { $0.art == .warmwasser || $0.art == .kaltwasser }
                .reduce(0) { $0 + $1.verbrauch }
        }
        return max(0, wasserWohnungZaehlerEnde - wasserWohnungZaehlerAnfang)
    }

    var warmwasserVerbrauch: Double {
        if !wasserzaehler.isEmpty {
            return wasserzaehler
                .filter { $0.art == .warmwasser }
                .reduce(0) { $0 + $1.verbrauch }
        }
        return max(0, wasserWohnungZaehlerEnde - wasserWohnungZaehlerAnfang)
    }

    var kaltwasserVerbrauch: Double {
        if !wasserzaehler.isEmpty {
            return wasserzaehler
                .filter { $0.art == .kaltwasser || $0.art == .waschkueche }
                .reduce(0) { $0 + $1.verbrauch }
        }
        return wasserWaschkuecheVerbrauch
    }

    var wasserWaschkuecheVerbrauch: Double {
        if !wasserzaehler.isEmpty {
            return wasserzaehler
                .filter { $0.art == .waschkueche }
                .reduce(0) { $0 + $1.verbrauch }
        }
        return max(0, wasserWaschkuecheZaehlerEnde - wasserWaschkuecheZaehlerAnfang)
    }
    
    /// Gesamtgebühr für diese Wohnung
    var gesamtgebuehr: Double {
        (abrechnungsErgebnis?.gesamtgebuehr ?? 0)
    }
    
    /// Zahlungsabweichung (Soll - Ist)
    var zahlungsabweichung: Double {
        (abrechnungsErgebnis?.zahlungsabweichung ?? 0)
    }
}

/// Eine Kostenart (z.B. "Miete", "Nebenkosten", "Versicherung")
@Model final class Kostenart {
    var id: UUID = UUID()
    var name: String
    var beschreibung: String?
    var category: KostenartKategorie
    
    init(name: String, category: KostenartKategorie) {
        self.name = name
        self.category = category
    }
}

enum KostenartKategorie: String, Codable {
    case miete = "Miete"
    case nebenkosten = "Nebenkosten"
    case versicherung = "Versicherung"
    case verwaltung = "Verwaltung"
    case sonstiges = "Sonstiges"
}

@Model final class AuslagenEintrag {
    var id: UUID = UUID()
    var monat: Int
    var betrag: Double
    var verwendungszweck: String
    var kaufort: String
    var datum: Date
    var weg: WEG?

    init(monat: Int, betrag: Double, verwendungszweck: String, kaufort: String, datum: Date = Date(), weg: WEG? = nil) {
        self.monat = monat
        self.betrag = betrag
        self.verwendungszweck = verwendungszweck
        self.kaufort = kaufort
        self.datum = datum
        self.weg = weg
    }
}

@Model final class AusgabenItem {
    var id: UUID = UUID()
    var kategorie: String
    var monat: Int
    var betrag: Double
    var weg: WEG?

    init(kategorie: String, monat: Int, betrag: Double, weg: WEG? = nil) {
        self.kategorie = kategorie
        self.monat = monat
        self.betrag = betrag
        self.weg = weg
    }
}

/// Ein Zahlungsitem für eine Wohnung
@Model final class ZahlungsItem {
    var id: UUID = UUID()
    var kostenart: String  // z.B. "Hausgeld"
    var betrag: Double
    var monat: Int = 0     // 1–12 = Monat, 0 = Jahresbetrag (Legacy)
    var wohnung: Wohnung?
    
    init(kostenart: String, betrag: Double, monat: Int = 0) {
        self.kostenart = kostenart
        self.betrag = betrag
        self.monat = monat
    }
}

/// Das Abrechnungsergebnis für eine Wohnung (W107, W207, etc.)
@Model final class AbrechnungsErgebnis {
    var id: UUID = UUID()
    var wohnung: Wohnung?
    
    // Heizung
    var heizungAnteil30Prozent: Double = 0      // Nach Fläche
    var heizungAnteil70Prozent: Double = 0      // Nach Heizpunkten
    var heizungGesamt: Double = 0
    
    // Wasser
    var wasserAnteil30Prozent: Double = 0       // Warmwasser 30% nach Fläche
    var wasserAnteil70Prozent: Double = 0       // Warmwasser 70% nach m³
    var wasserGesamt: Double = 0                // Warmwasser gesamt
    var kaltwasserGesamt: Double = 0            // Kaltwasser nach m³
    
    // Sonstige Kosten
    var sonstigeKosten: Double = 0
    
    // Gesamten & Differenz
    var gesamtgebuehr: Double {
        heizungGesamt + wasserGesamt + kaltwasserGesamt + sonstigeKosten
    }
    
    var zahlungsabweichung: Double = 0  // Soll - Ist
    
    var berechnungsDatum: Date = Date()

    init(wohnung: Wohnung? = nil) {
        self.wohnung = wohnung
    }
}

// MARK: - Helper für Formeln

/// Service für Abrechnungs-Berechnungen
class AbrechnungsService {
    
    /// Berechnet die 30/70-Umlage für Heizung/Wasser
    static func berechneFlaechenUndVerbrauchsAnteil(
        meineFlaecheQm: Double,
        meinVerbrauch: Double,
        gesamtFlaecheQm: Double,
        gesamtVerbrauch: Double,
        gesamtKosten: Double
    ) -> (anteil30: Double, anteil70: Double, gesamt: Double) {
        
        let flaechen30Prozent: Double
        if gesamtFlaecheQm > 0 {
            flaechen30Prozent = (meineFlaecheQm / gesamtFlaecheQm) * 0.3 * gesamtKosten
        } else {
            flaechen30Prozent = 0
        }
        
        let verbrauchs70Prozent: Double
        if gesamtVerbrauch > 0 {
            verbrauchs70Prozent = (meinVerbrauch / gesamtVerbrauch) * 0.7 * gesamtKosten
        } else {
            verbrauchs70Prozent = 0
        }
        
        let gesamt = flaechen30Prozent + verbrauchs70Prozent
        
        return (anteil30: flaechen30Prozent, anteil70: verbrauchs70Prozent, gesamt: gesamt)
    }
    
    /// Berechnet die Abrechnung aus den Hauptabrechnungswerten und verteilt auf Wohnungen.
    static func berechneAbrechnung(weg: WEG) {
        let gesamtFlaeche = weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm }
        let gesamtHeizPunkte = weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch }
        let gesamtWarmwasserM3 = weg.wohnungen.reduce(0) { $0 + $1.warmwasserVerbrauch }
        let gesamtKaltwasserM3 = weg.wohnungen.reduce(0) { $0 + $1.kaltwasserVerbrauch }

        let heizkosten30Topf = weg.heizkostenBrennstoffEuro * 0.3
        let heizkosten70Topf = weg.heizkostenBrennstoffEuro * 0.7

        let warmwasser30Topf = weg.warmwasserkostenGesamtEuro * 0.3
        let warmwasser70Topf = weg.warmwasserkostenGesamtEuro * 0.7

        let kaltwasserTopfVerbrauch = weg.kaltwasserkostenVerbrauchsanteilEuro
        let niederschlagswasserProWohnung = weg.abrechnungsjahr >= 2026 ? max(0, weg.niederschlagswasserEuro) / 6.0 : 0

        for wohnung in weg.wohnungen {
            let ergebnis = wohnung.abrechnungsErgebnis ?? AbrechnungsErgebnis(wohnung: wohnung)

            // Heizung (nur Brennstoffanteil) 30/70
            let heiz30 = gesamtFlaeche > 0 ? (wohnung.flaeche_qm / gesamtFlaeche) * heizkosten30Topf : 0
            let heiz70 = gesamtHeizPunkte > 0 ? (wohnung.heizungVerbrauch / gesamtHeizPunkte) * heizkosten70Topf : 0
            ergebnis.heizungAnteil30Prozent = heiz30
            ergebnis.heizungAnteil70Prozent = heiz70
            ergebnis.heizungGesamt = heiz30 + heiz70

            // Warmwasser 30/70
            let ww30 = gesamtFlaeche > 0 ? (wohnung.flaeche_qm / gesamtFlaeche) * warmwasser30Topf : 0
            let ww70 = gesamtWarmwasserM3 > 0 ? (wohnung.warmwasserVerbrauch / gesamtWarmwasserM3) * warmwasser70Topf : 0
            ergebnis.wasserAnteil30Prozent = ww30
            ergebnis.wasserAnteil70Prozent = ww70
            ergebnis.wasserGesamt = ww30 + ww70

            // Kaltwasser 100% nach Kaltwasser-Verbrauch
            let kwVerbrauch = gesamtKaltwasserM3 > 0 ? (wohnung.kaltwasserVerbrauch / gesamtKaltwasserM3) * kaltwasserTopfVerbrauch : 0
            let kw = kwVerbrauch + niederschlagswasserProWohnung
            ergebnis.kaltwasserGesamt = kw

            // Fixkosten-Anteil je Wohnung (gleiche Formel wie fixedOhneHeizung in AbrechnungDetailView).
            // Damit ist gesamtgebuehr = HKV + Fixkosten = Gesamtbetrag je Wohnung,
            // und heizungVerbrauchAnteil = gesamtgebuehr - fixedOhneHeizung = HKV > 0.
            let n = max(1.0, Double(weg.wohnungen.count))
            let gesamtPersonen = max(1, weg.wohnungen.reduce(0) { $0 + max(1, $1.personenanzahl) })
            let fixedPerUnit = (weg.verguetungHmtEuro / n)
                + (weg.heizungWartungRepEuro / n)
                + (weg.allgemeinStromEuro / n)
                + (weg.muellGebuehrenEuro / Double(gesamtPersonen) * Double(max(1, wohnung.personenanzahl)))
                + (weg.versicherungenGesamtEuro / n)
                + (weg.hausUndGrundEuro / n)
                + (weg.nebenkostenGeldverkehrEuro / n)
                + (weg.reparaturenAnschaffungenEuro / n)
                + (weg.ruecklagenEuro / n)
            ergebnis.sonstigeKosten = fixedPerUnit

            // Differenz = Vorauszahlungen (Soll) - errechneter Umlageanteil
            let vorauszahlungen = wohnung.zahlungen
                .filter { $0.monat >= 1 && $0.monat <= 12 }
                .reduce(0) { $0 + $1.betrag }
            ergebnis.zahlungsabweichung = vorauszahlungen - ergebnis.gesamtgebuehr

            wohnung.abrechnungsErgebnis = ergebnis
        }
    }
}
