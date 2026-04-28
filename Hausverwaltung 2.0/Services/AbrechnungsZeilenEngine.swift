import Foundation
import SwiftData

struct AbrechnungsAusgabeZeile {
    let name: String
    let total: Double
    let keyTotal: Double
    let keyLabel: String
    let keyValue: Double
    let amount: Double
    let isSub: Bool
    let isBold: Bool
}

private struct StandardAbrechnungsZeileDefinition {
    let systemCode: String
    let name: String
    let schluesselArt: VerteilungsschluesselArt
    let sortierung: Int
    let betragQuellen: [AbrechnungsWertQuelle]
    let schluesselGesamtQuelle: AbrechnungsWertQuelle
    let schluesselWertQuelle: AbrechnungsWertQuelle
    let schluesselBezeichnungOverride: String
    let anteilsModell: AbrechnungsAnteilModell
    let wohnungsBetragQuelle: AbrechnungsWertQuelle
}

enum AbrechnungsZeilenEngine {
    static func resolveHaushaltPersonen(
        fuer wohnung: Wohnung,
        in weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Int {
        let profileImJahr = eigentuemerProfile.filter { $0.abrechnungsjahr == weg.abrechnungsjahr }
        let wohnungsProfil = profileImJahr.first { $0.wohnungsnummer == wohnung.wohnungsnummer }

        if wohnung.personenanzahl > 0 {
            return max(1, wohnung.personenanzahl)
        }
        if let wohnungsProfil {
            return max(1, wohnungsProfil.haushaltPersonen)
        }
        return 1
    }

    static func resolveHaushaltPersonenGesamt(
        in weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Int {
        weg.wohnungen.reduce(0) { summe, wohnung in
            summe + resolveHaushaltPersonen(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile)
        }
    }

    static func resolveMiteigentumsanteil(
        fuer wohnung: Wohnung,
        in weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Int {
        let profileImJahr = eigentuemerProfile.filter { $0.abrechnungsjahr == weg.abrechnungsjahr }
        let wohnungsProfil = profileImJahr.first { $0.wohnungsnummer == wohnung.wohnungsnummer }

        if wohnung.eigentumsanteilTausendstel > 0 {
            return wohnung.eigentumsanteilTausendstel
        }
        if let wohnungsProfil, wohnungsProfil.eigentumsanteilTausendstel > 0 {
            return wohnungsProfil.eigentumsanteilTausendstel
        }
        return Int(max(1.0, 1000.0 / Double(max(1, weg.wohnungen.count))))
    }

    static func resolveMiteigentumsanteilGesamt(
        in weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Int {
        let summe = weg.wohnungen.reduce(0) { summe, wohnung in
            summe + resolveMiteigentumsanteil(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile)
        }
        return max(1, summe)
    }

    static func standardZeilen(abrechnungsjahr: Int) -> [AbrechnungsZeileKonfiguration] {
        standardDefinitionen(abrechnungsjahr: abrechnungsjahr).map { definition in
            let zeile = AbrechnungsZeileKonfiguration(
                abrechnungsjahr: abrechnungsjahr,
                name: definition.name,
                gesamtbetragEuro: 0,
                schluesselArt: definition.schluesselArt,
                istGlobal: true,
                wohnungsnummer: nil,
                gesamtSchluesselManuell: 0,
                wohnungsSchluesselManuell: 0,
                sortierung: definition.sortierung,
                aktiv: true
            )
            zeile.systemCode = definition.systemCode
            zeile.istStandard = true
            zeile.setBetragQuellen(definition.betragQuellen)
            zeile.setSchluesselGesamtQuelle(definition.schluesselGesamtQuelle)
            zeile.setSchluesselWertQuelle(definition.schluesselWertQuelle)
            zeile.setWohnungsBetragQuelle(definition.wohnungsBetragQuelle)
            zeile.setAnteilsModell(definition.anteilsModell)
            zeile.schluesselBezeichnungOverride = definition.schluesselBezeichnungOverride
            return zeile
        }
    }

    static func baueAusgabezeilen(
        wohnung: Wohnung,
        weg: WEG,
        zeilenKonfiguration: [AbrechnungsZeileKonfiguration],
        eigentuemerProfile: [EigentuemerProfil]
    ) -> [AbrechnungsAusgabeZeile] {
        let zeilen = zeilenKonfiguration
            .filter {
                $0.abrechnungsjahr == weg.abrechnungsjahr
                && $0.aktiv
                && ($0.istGlobal || $0.wohnungsnummer == wohnung.wohnungsnummer)
            }
            .sorted {
                if $0.sortierung != $1.sortierung { return $0.sortierung < $1.sortierung }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        return zeilen.flatMap { zeile in
            let total = resolveGesamtbetrag(for: zeile, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            let schluessel = resolveSchluessel(for: zeile, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            let amount = resolveWohnungsbetrag(
                for: zeile,
                total: total,
                schluessel: schluessel,
                wohnung: wohnung,
                weg: weg,
                eigentuemerProfile: eigentuemerProfile
            )

            let hauptzeile = AbrechnungsAusgabeZeile(
                name: zeile.name,
                total: total,
                keyTotal: schluessel.total,
                keyLabel: schluessel.label,
                keyValue: schluessel.value,
                amount: amount,
                isSub: false,
                isBold: false
            )

            let unterzeilen = zeile.betragQuellen.count > 1
                ? zeile.betragQuellen.map { quelle in
                    AbrechnungsAusgabeZeile(
                        name: quelle.anzeigeName,
                        total: resolveQuelle(quelle, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile),
                        keyTotal: 0,
                        keyLabel: "",
                        keyValue: 0,
                        amount: 0,
                        isSub: true,
                        isBold: false
                    )
                }
                : []

            return [hauptzeile] + unterzeilen
        }
    }

    static func resolveGesamtbetrag(
        for zeile: AbrechnungsZeileKonfiguration,
        wohnung: Wohnung,
        weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Double {
        let quellen = zeile.betragQuellen
        if quellen.isEmpty {
            return zeile.gesamtbetragEuro
        }
        return quellen.reduce(0) { summe, quelle in
            summe + resolveQuelle(quelle, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
        }
    }

    static func resolveSchluessel(
        for zeile: AbrechnungsZeileKonfiguration,
        wohnung: Wohnung,
        weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> (total: Double, value: Double, label: String) {
        let total: Double
        if zeile.gesamtSchluesselManuell > 0 {
            total = zeile.gesamtSchluesselManuell
        } else if zeile.schluesselGesamtQuelleSicher != .none {
            total = resolveQuelle(zeile.schluesselGesamtQuelleSicher, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
        } else {
            total = fallbackSchluessel(for: zeile, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile).total
        }

        let value: Double
        if let perWohnung = zeile.wohnungsSchluessel(fuer: wohnung.wohnungsnummer) {
            value = perWohnung
        } else if zeile.wohnungsSchluesselManuell > 0 {
            value = zeile.wohnungsSchluesselManuell
        } else if zeile.schluesselWertQuelleSicher != .none {
            value = resolveQuelle(zeile.schluesselWertQuelleSicher, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
        } else {
            value = fallbackSchluessel(for: zeile, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile).value
        }

        return (total, value, zeile.schluesselBezeichnungAnzeige)
    }

    static func resolveWohnungsbetrag(
        for zeile: AbrechnungsZeileKonfiguration,
        total: Double,
        schluessel: (total: Double, value: Double, label: String),
        wohnung: Wohnung,
        weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Double {
        switch zeile.anteilsModellSicher {
        case .proportional:
            return schluessel.total > 0 ? total * (schluessel.value / schluessel.total) : 0
        case .direkterBetrag:
            return resolveQuelle(zeile.wohnungsBetragQuelleSicher, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
        }
    }

    private static func fallbackSchluessel(
        for zeile: AbrechnungsZeileKonfiguration,
        wohnung: Wohnung,
        weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> (total: Double, value: Double) {
        let n = max(1.0, Double(weg.wohnungen.count))
        switch zeile.schluesselArt {
        case .wohneinheiten:
            return (n, 1)
        case .personen:
            let total = resolveQuelle(.haushaltPersonenGesamt, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            let value = resolveQuelle(.haushaltPersonenWohnung, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            return (total, value)
        case .flaeche:
            return (
                resolveQuelle(.wohnflaecheGesamt, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile),
                resolveQuelle(.wohnflaecheWohnung, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            )
        case .verbrauch:
            return (
                resolveQuelle(.heizungVerbrauchGesamt, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile),
                resolveQuelle(.heizungVerbrauchWohnung, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            )
        case .miteigentumsanteile:
            return (
                resolveQuelle(.miteigentumsanteileGesamt, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile),
                resolveQuelle(.miteigentumsanteileWohnung, wohnung: wohnung, weg: weg, eigentuemerProfile: eigentuemerProfile)
            )
        }
    }

    private static func resolveQuelle(
        _ quelle: AbrechnungsWertQuelle,
        wohnung: Wohnung,
        weg: WEG,
        eigentuemerProfile: [EigentuemerProfil]
    ) -> Double {
        switch quelle {
        case .none:
            return 0
        case .constantOne:
            return 1
        case .wohnungsanzahl:
            return Double(max(1, weg.wohnungen.count))
        case .verguetungHmtEuro:
            return weg.verguetungHmtEuro
        case .heizkostenBrennstoffEuro:
            return weg.heizkostenBrennstoffEuro
        case .gesamtwasserbetragLtRechnungEuro:
            return weg.gesamtwasserbetragLtRechnungEuro
        case .schornsteinfegerEuro:
            return weg.schornsteinfegerEuro
        case .wartungBaurEuro:
            return weg.wartungBaurEuro
        case .allgemeinStromEuro:
            return weg.allgemeinStromEuro
        case .muellGebuehrenEuro:
            return weg.muellGebuehrenEuro
        case .muellGesamtPersonen:
            return Double(resolveHaushaltPersonenGesamt(in: weg, eigentuemerProfile: eigentuemerProfile))
        case .wohnungPersonen:
            return Double(resolveHaushaltPersonen(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile))
        case .versicherungGebaeudeMitFeuerEuro:
            return weg.versicherungGebaeudeMitFeuerEuro
        case .versicherungHausHaftpflichtEuro:
            return weg.versicherungHausHaftpflichtEuro
        case .hausUndGrundEuro:
            return weg.hausUndGrundEuro
        case .nebenkostenGeldverkehrEuro:
            return weg.nebenkostenGeldverkehrEuro
        case .reparaturenAnschaffungenEuro:
            return weg.reparaturenAnschaffungenEuro
        case .ruecklagenEuro:
            return weg.ruecklagenEuro
        case .wohnflaecheGesamt:
            return max(0.0001, weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm })
        case .wohnflaecheWohnung:
            return wohnung.flaeche_qm
        case .heizungVerbrauchGesamt:
            return max(0.0001, weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch })
        case .heizungVerbrauchWohnung:
            return wohnung.heizungVerbrauch
        case .miteigentumsanteileGesamt:
            return Double(resolveMiteigentumsanteilGesamt(in: weg, eigentuemerProfile: eigentuemerProfile))
        case .miteigentumsanteileWohnung:
            return Double(resolveMiteigentumsanteil(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile))
        case .haushaltPersonenGesamt:
            return Double(resolveHaushaltPersonenGesamt(in: weg, eigentuemerProfile: eigentuemerProfile))
        case .haushaltPersonenWohnung:
            return Double(resolveHaushaltPersonen(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile))
        case .heizungVerbrauchAnteil:
            guard let ergebnis = wohnung.abrechnungsErgebnis else { return 0 }
            let n = max(1.0, Double(weg.wohnungen.count))
            let heizungWartungRepGesamt = weg.schornsteinfegerEuro + weg.wartungBaurEuro
            let fixedOhneHeizung =
                (weg.verguetungHmtEuro / n)
                + (heizungWartungRepGesamt / n)
                + (weg.allgemeinStromEuro / n)
                + (weg.muellGebuehrenEuro
                    / Double(resolveHaushaltPersonenGesamt(in: weg, eigentuemerProfile: eigentuemerProfile))
                    * Double(resolveHaushaltPersonen(fuer: wohnung, in: weg, eigentuemerProfile: eigentuemerProfile)))
                + (weg.versicherungenGesamtEuro / n)
                + (weg.hausUndGrundEuro / n)
                + (weg.nebenkostenGeldverkehrEuro / n)
                + (weg.reparaturenAnschaffungenEuro / n)
                + (weg.ruecklagenEuro / n)
            return max(0, ergebnis.gesamtgebuehr - fixedOhneHeizung)
        }
    }

    private static func standardDefinitionen(abrechnungsjahr: Int) -> [StandardAbrechnungsZeileDefinition] {
        [
            StandardAbrechnungsZeileDefinition(systemCode: "verg_hmt", name: "Vergütung Techn. Hausbetr.", schluesselArt: .wohneinheiten, sortierung: 0, betragQuellen: [.verguetungHmtEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "heizung_verbrauch", name: "Heizung Verbrauch", schluesselArt: .wohneinheiten, sortierung: 1, betragQuellen: [.heizkostenBrennstoffEuro, .gesamtwasserbetragLtRechnungEuro], schluesselGesamtQuelle: .none, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Abrechnung", anteilsModell: .direkterBetrag, wohnungsBetragQuelle: .heizungVerbrauchAnteil),
            StandardAbrechnungsZeileDefinition(systemCode: "heizung_wartung", name: "Heizung Wartung/Rep.", schluesselArt: .wohneinheiten, sortierung: 2, betragQuellen: [.schornsteinfegerEuro, .wartungBaurEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "allgemein_strom", name: "Allgemein Strom", schluesselArt: .wohneinheiten, sortierung: 3, betragQuellen: [.allgemeinStromEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "muell", name: "Müllgebühren", schluesselArt: .personen, sortierung: 4, betragQuellen: [.muellGebuehrenEuro], schluesselGesamtQuelle: .muellGesamtPersonen, schluesselWertQuelle: .wohnungPersonen, schluesselBezeichnungOverride: "Personen", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "versicherungen", name: "Versicherungen", schluesselArt: .miteigentumsanteile, sortierung: 5, betragQuellen: [.versicherungGebaeudeMitFeuerEuro, .versicherungHausHaftpflichtEuro], schluesselGesamtQuelle: .miteigentumsanteileGesamt, schluesselWertQuelle: .miteigentumsanteileWohnung, schluesselBezeichnungOverride: "Miteigent. Anteil", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "haus_grund", name: "Haus & Grund Mitgliedschaft", schluesselArt: .wohneinheiten, sortierung: 6, betragQuellen: [.hausUndGrundEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "geldverkehr", name: "Nebenkosten Geldverkehr", schluesselArt: .wohneinheiten, sortierung: 7, betragQuellen: [.nebenkostenGeldverkehrEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "reparaturen", name: "Reparaturen/Anschaffungen", schluesselArt: .wohneinheiten, sortierung: 8, betragQuellen: [.reparaturenAnschaffungenEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
            StandardAbrechnungsZeileDefinition(systemCode: "ruecklagen", name: "Rücklagen \(abrechnungsjahr)", schluesselArt: .wohneinheiten, sortierung: 9, betragQuellen: [.ruecklagenEuro], schluesselGesamtQuelle: .wohnungsanzahl, schluesselWertQuelle: .constantOne, schluesselBezeichnungOverride: "Wohneinheiten", anteilsModell: .proportional, wohnungsBetragQuelle: .none),
        ]
    }
}