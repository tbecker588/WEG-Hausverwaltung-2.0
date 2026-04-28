//
//  AbrechnungZahlungenView.swift
//  Hausverwaltung 2.0
//

import SwiftUI

// MARK: - Kontext für Zellbearbeitung

private struct EditCellContext: Identifiable {
    let id = UUID()
    let label: String
    let aktuell: Double
    let speichern: (Double) -> Void
    /// Wenn gesetzt, kann der Nutzer den Wert auf alle Monate übernehmen.
    var alleMonateSpeichern: ((Double) -> Void)? = nil
    /// Wenn true, erscheint ein Gutschrift/Nachzahlung-Picker im Sheet.
    var erlaubtNegativ: Bool = false
}

private struct AuslagenMonatContext: Identifiable {
    let id = UUID()
    let monat: Int
}

// MARK: - Hauptansicht

struct AbrechnungZahlungenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @State private var editCtx: EditCellContext?

    var body: some View {
        NavigationStack {
            Group {
                if let weg = viewModel.weg {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if viewModel.istJahrSchreibgeschuetzt {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.istHistorischesJahr ? "eye.fill" : "lock.fill")
                                    Text(viewModel.schreibschutzHinweis)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, 16)
                            }

                            Text("Ein- und Ausgaben WEG Uhlandstr. 12 · Jahr " + String(weg.abrechnungsjahr))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            ZahlungenEinnahmenTabelle(weg: weg, viewModel: viewModel, editCtx: $editCtx, readonly: viewModel.istJahrSchreibgeschuetzt)
                            ZahlungenAusgabenTabelle(weg: weg, viewModel: viewModel, editCtx: $editCtx, readonly: viewModel.istJahrSchreibgeschuetzt)
                            ZahlungenZusammenfassung(weg: weg, viewModel: viewModel, editCtx: $editCtx, readonly: viewModel.istJahrSchreibgeschuetzt)
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .background(Color(.systemGroupedBackground))
                } else {
                    ContentUnavailableView("Keine Daten", systemImage: "tray")
                }
            }
            .navigationTitle("Zahlungen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Tastatur zu", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
        .appKeyboardToolbar()
        .sheet(item: $editCtx) { ctx in
            ZahlungEingabeSheet(ctx: ctx)
        }
    }
}

// MARK: - Eingabe-Sheet

private struct ZahlungEingabeSheet: View {
    let ctx: EditCellContext
    @State private var text: String = ""
    @State private var alleMonateToggle: Bool = false
    /// -1 = Gutschrift (senkt Ausgaben), 1 = Nachzahlung (erhoeht Ausgaben)
    @State private var vorzeichen: Int = 1
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    private var sheetHeight: CGFloat {
        var h: CGFloat = 280
        if ctx.erlaubtNegativ { h += 80 }
        if ctx.alleMonateSpeichern != nil { h += 80 }
        return h
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(ctx.label) {
                    TextField("Betrag in €", text: $text)
                        .keyboardType(.decimalPad)
                        .focused($focused)
                }
                if ctx.erlaubtNegativ {
                    Section {
                        Picker("Art", selection: $vorzeichen) {
                            Text("Gutschrift").tag(-1)
                            Text("Nachzahlung").tag(1)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Art der Korrektur")
                    }
                }
                Section {
                    HStack {
                        Text("Aktueller Wert")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f €", ctx.aktuell))
                            .fontWeight(.semibold)
                            .foregroundStyle(ctx.aktuell < 0 ? .green : (ctx.aktuell > 0 ? .red : .primary))
                    }
                }
                if ctx.alleMonateSpeichern != nil {
                    Section {
                        Toggle(isOn: $alleMonateToggle) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Für alle Monate übernehmen")
                                    .font(.body)
                                Text("Ersetzt den Wert in allen 12 Monaten")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Betrag ändern")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let absVal = Double(text.replacingOccurrences(of: ",", with: ".")) ?? abs(ctx.aktuell)
                        let val = ctx.erlaubtNegativ ? absVal * Double(vorzeichen) : absVal
                        if alleMonateToggle, let alleSpeichern = ctx.alleMonateSpeichern {
                            alleSpeichern(val)
                        } else {
                            ctx.speichern(val)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            let v = ctx.aktuell
            vorzeichen = v > 0 ? 1 : -1
            text = v != 0 ? String(format: "%.2f", abs(v)) : ""
            focused = true
        }
        .presentationDetents([.height(sheetHeight)])
    }
}

// MARK: - Einnahmen-Tabelle

private struct ZahlungenEinnahmenTabelle: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    @Binding var editCtx: EditCellContext?
    let readonly: Bool

    private var wohnungen: [Wohnung] { weg.wohnungenSortiert }
    private var showHmtUndRl: Bool { weg.abrechnungsjahr < 2026 }

    private static let mn = ["Jan","Feb","Mär","Apr","Mai","Jun",
                              "Jul","Aug","Sep","Okt","Nov","Dez"]

    private func betrag(_ w: Wohnung, _ monat: Int) -> Double {
        w.zahlungen.filter { $0.monat == monat }.reduce(0) { $0 + $1.betrag }
    }

    private func hmt(_ monat: Int) -> Double {
        if let wert = weg.ausgaben.first(where: { $0.kategorie == "HMT" && $0.monat == monat })?.betrag {
            return wert
        }
        return weg.verguetungHmtEuro / 12
    }

    private func rl(_ monat: Int) -> Double {
        if let wert = weg.ausgaben.first(where: { $0.kategorie == "WEG Rücklagen" && $0.monat == monat })?.betrag {
            return wert
        }
        return weg.ruecklagenEuro / 12
    }

    private func zGesamt(_ monat: Int) -> Double {
        wohnungen.reduce(0) { $0 + betrag($1, monat) }
    }

    private func jahresSumme(_ w: Wohnung) -> Double {
        w.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
    }

    private var hmtJahr: Double { (1...12).reduce(0.0) { $0 + hmt($1) } }
    private var rlJahr: Double  { (1...12).reduce(0.0) { $0 + rl($1) } }
    private var gesamtJahr: Double { wohnungen.reduce(0) { $0 + jahresSumme($1) } }

    private let cM: CGFloat = 44
    private let cW: CGFloat = 68
    private let cG: CGFloat = 74
    private let cH: CGFloat = 60
    private let cR: CGFloat = 84

    var body: some View {
        TabellenKarte(titel: "Einnahmen", icon: "arrow.down.circle.fill", iconColor: .green) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        kopfZelle("Monat", cM, links: true)
                        ForEach(wohnungen) { w in kopfZelle(w.eigentuemer, cW) }
                        kopfZelle("Gesamt", cG)
                        if showHmtUndRl {
                            kopfZelle("HMT", cH)
                            kopfZelle("WEG RL", cR)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    Divider()

                    ForEach(1...12, id: \.self) { m in
                        HStack(spacing: 0) {
                            Text(Self.mn[m - 1])
                                .frame(width: cM, alignment: .leading)
                                .font(.caption).foregroundStyle(.secondary)

                            ForEach(wohnungen) { w in
                                let b = betrag(w, m)
                                TapZelle(value: b, width: cW) {
                                    guard !readonly else { return }
                                    editCtx = EditCellContext(
                                        label: "\(w.eigentuemer) · \(Self.mn[m-1])",
                                        aktuell: b,
                                        speichern: { val in
                                            if let ex = w.zahlungen.first(where: { $0.monat == m }) {
                                                ex.betrag = val
                                            } else {
                                                let neu = ZahlungsItem(kostenart: "Hausgeld", betrag: val, monat: m)
                                                neu.wohnung = w
                                                w.zahlungen.append(neu)
                                            }
                                            viewModel.saveWEG()
                                        },
                                        alleMonateSpeichern: { val in
                                            for monat in 1...12 {
                                                if let ex = w.zahlungen.first(where: { $0.monat == monat }) {
                                                    ex.betrag = val
                                                } else {
                                                    let neu = ZahlungsItem(kostenart: "Hausgeld", betrag: val, monat: monat)
                                                    neu.wohnung = w
                                                    w.zahlungen.append(neu)
                                                }
                                            }
                                            viewModel.saveWEG()
                                        }
                                    )
                                }
                            }

                            Text(String(format: "%.0f", zGesamt(m)))
                                .frame(width: cG, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)

                            if showHmtUndRl {
                                let h = hmt(m)
                                TapZelle(value: h, width: cH) {
                                    guard !readonly else { return }
                                    editCtx = EditCellContext(
                                        label: "HMT · \(Self.mn[m-1])",
                                        aktuell: h,
                                        speichern: { val in viewModel.setAusgabe(weg: weg, monat: m, kategorie: "HMT", betrag: val) },
                                        alleMonateSpeichern: { val in
                                            for monat in 1...12 { viewModel.setAusgabe(weg: weg, monat: monat, kategorie: "HMT", betrag: val) }
                                        }
                                    )
                                }

                                let r = rl(m)
                                TapZelle(value: r, width: cR) {
                                    guard !readonly else { return }
                                    editCtx = EditCellContext(
                                        label: "WEG Rücklagen · \(Self.mn[m-1])",
                                        aktuell: r,
                                        speichern: { val in viewModel.setAusgabe(weg: weg, monat: m, kategorie: "WEG Rücklagen", betrag: val) },
                                        alleMonateSpeichern: { val in
                                            for monat in 1...12 { viewModel.setAusgabe(weg: weg, monat: monat, kategorie: "WEG Rücklagen", betrag: val) }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 7)
                        .background(m % 2 == 0 ? Color.clear : Color(.quaternarySystemFill))
                        if m < 12 { Divider().padding(.leading, cM) }
                    }

                    Divider()
                    HStack(spacing: 0) {
                        Text("Gesamt")
                            .frame(width: cM, alignment: .leading)
                            .font(.caption).fontWeight(.bold)
                        ForEach(wohnungen) { w in
                            Text(String(format: "%.0f", jahresSumme(w)))
                                .frame(width: cW, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)
                        }
                        Text(String(format: "%.0f", gesamtJahr))
                            .frame(width: cG, alignment: .trailing)
                            .font(.caption).fontWeight(.bold).foregroundStyle(.green)
                        if showHmtUndRl {
                            Text(String(format: "%.0f", hmtJahr))
                                .frame(width: cH, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)
                            Text(String(format: "%.0f", rlJahr))
                                .frame(width: cR, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.07))
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Ausgaben-Tabelle

private struct ZahlungenAusgabenTabelle: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    @Binding var editCtx: EditCellContext?
    let readonly: Bool
    @State private var showAddKategorie = false
    @State private var neueKategorie = ""
    @State private var auslagenMonatCtx: AuslagenMonatContext?
    @State private var showAuslagenListe = false

    private static let mn = ["Jan","Feb","Mär","Apr","Mai","Jun",
                              "Jul","Aug","Sep","Okt","Nov","Dez"]

    private var kategorien: [(kuerzel: String, key: String)] {
        viewModel.ausgabenKategorien(fuer: weg).map { key in
            let kuerzel: String
            switch key {
            case "Strom VaFa": kuerzel = "Strom"
            case "fairenergie Gas": kuerzel = "Gas"
            case "Schornstein": kuerzel = "Schorn."
            case "Haus und Grund": kuerzel = "H&G"
            case "Auslagen HM": kuerzel = "Auslagen"
            default: kuerzel = key.count > 10 ? String(key.prefix(10)) + "…" : key
            }
            return (kuerzel: kuerzel, key: key)
        }
    }

    private let cM: CGFloat = 44
    private let cK: CGFloat = 78
    private let cS: CGFloat = 84

    private var hatAuslagenEintraege: Bool {
        !viewModel.auslagenEintraege(fuer: weg).isEmpty
    }

    private func fallbackMonatswert(_ key: String) -> Double {
        switch key {
        case "Strom VaFa": return weg.allgemeinStromEuro / 12
        case "Gas", "fairenergie Gas": return weg.brennstoffverbrauchKwh > 0 ? (weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro) / 12 : 0
        case "Schornstein": return weg.schornsteinfegerEuro / 12
        case "Müll": return weg.muellGebuehrenEuro / 12
        case "Wasser": return weg.gesamtwasserbetragLtRechnungEuro / 12
        case "H&G", "Haus und Grund": return weg.hausUndGrundEuro / 12
        case "Baur": return weg.wartungBaurEuro / 12
        case "Auslagen HM": return weg.nebenkostenGeldverkehrEuro / 12
        default: return 0
        }
    }

    private func wert(_ monat: Int, _ key: String) -> Double {
        if key == "Auslagen HM" && monat >= 1 && monat <= 12 {
            return viewModel.summeAuslagen(fuer: weg, monat: monat)
        }
        if let wert = weg.ausgaben.first(where: { $0.monat == monat && $0.kategorie == key })?.betrag {
            return wert
        }
        // monat 13 = Korrekturen, kein Fallback
        if monat == 13 { return 0 }
        return fallbackMonatswert(key)
    }

    private func korrWert(_ key: String) -> Double { wert(13, key) }

    private func zSumme(_ m: Int) -> Double {
        kategorien.reduce(0) { $0 + wert(m, $1.key) }
    }

    private func spalte(_ key: String) -> Double {
        (1...12).reduce(0.0) { $0 + wert($1, key) } + korrWert(key)
    }

    private var gesamt: Double { kategorien.reduce(0) { $0 + spalte($1.key) } }

    var body: some View {
        TabellenKarte(titel: "Ausgaben", icon: "arrow.up.circle.fill", iconColor: .orange) {
            HStack {
                Text("Spalten: \(kategorien.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showAuslagenListe = true
                } label: {
                    Label("Auslagenliste", systemImage: "list.bullet.rectangle")
                }
                .font(.caption)
                .disabled(!hatAuslagenEintraege)

                Button {
                    neueKategorie = ""
                    showAddKategorie = true
                } label: {
                    Label("Spalte hinzufügen", systemImage: "plus.circle")
                }
                .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        kopfZelle("Monat", cM, links: true)
                        ForEach(kategorien, id: \.key) { k in kopfZelle(k.kuerzel, cK) }
                        kopfZelle("Summe", cS)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    Divider()

                    ForEach(1...12, id: \.self) { m in
                        HStack(spacing: 0) {
                            Text(Self.mn[m - 1])
                                .frame(width: cM, alignment: .leading)
                                .font(.caption).foregroundStyle(.secondary)

                            ForEach(kategorien, id: \.key) { k in
                                let v = wert(m, k.key)
                                TapZelle(value: v, width: cK, decimals: 2) {
                                    guard !readonly else { return }
                                    if k.key == "Auslagen HM" {
                                        auslagenMonatCtx = AuslagenMonatContext(monat: m)
                                        return
                                    }
                                    editCtx = EditCellContext(
                                        label: "\(k.key) · \(Self.mn[m-1])",
                                        aktuell: v,
                                        speichern: { val in viewModel.setAusgabe(weg: weg, monat: m, kategorie: k.key, betrag: val) },
                                        alleMonateSpeichern: { val in
                                            for monat in 1...12 { viewModel.setAusgabe(weg: weg, monat: monat, kategorie: k.key, betrag: val) }
                                        }
                                    )
                                }
                            }

                            Text(String(format: "%.2f", zSumme(m)))
                                .frame(width: cS, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)
                        }
                        .padding(.vertical, 7)
                        .background(m % 2 == 0 ? Color.clear : Color(.quaternarySystemFill))
                        if m < 12 { Divider().padding(.leading, cM) }
                    }

                    // Korrekturen-Zeile (Gutschriften/Nachzahlungen)
                    Divider()
                    HStack(spacing: 0) {
                        Text("Korr.")
                            .frame(width: cM, alignment: .leading)
                            .font(.caption).foregroundStyle(.secondary)
                            .help("Gutschrift senkt die Ausgaben, Nachzahlung erhoeht sie")

                        ForEach(kategorien, id: \.key) { k in
                            let kv = korrWert(k.key)
                            TapZelle(value: kv, width: cK, decimals: 2, color: kv < 0 ? .green : (kv > 0 ? .red : nil)) {
                                guard !readonly else { return }
                                editCtx = EditCellContext(
                                    label: "\(k.key) · Gutschrift/Nachzahlung",
                                    aktuell: kv,
                                    speichern: { val in viewModel.setAusgabe(weg: weg, monat: 13, kategorie: k.key, betrag: val) },
                                    erlaubtNegativ: true
                                )
                            }
                        }

                        let korrGesamt = kategorien.reduce(0.0) { $0 + korrWert($1.key) }
                        Text(String(format: "%.2f", korrGesamt))
                            .frame(width: cS, alignment: .trailing)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(korrGesamt < 0 ? .green : (korrGesamt > 0 ? .red : .secondary))
                    }
                    .padding(.vertical, 7)
                    .background(Color(.quaternarySystemFill))

                    Divider()
                    HStack(spacing: 0) {
                        Text("Summe")
                            .frame(width: cM, alignment: .leading)
                            .font(.caption).fontWeight(.bold)
                        ForEach(kategorien, id: \.key) { k in
                            Text(String(format: "%.2f", spalte(k.key)))
                                .frame(width: cK, alignment: .trailing)
                                .font(.caption).fontWeight(.semibold)
                        }
                        Text(String(format: "%.2f", gesamt))
                            .frame(width: cS, alignment: .trailing)
                            .font(.caption).fontWeight(.bold).foregroundStyle(.orange)
                    }
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.07))
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 4)
        }
        .alert("Neue Ausgaben-Spalte", isPresented: $showAddKategorie) {
            TextField("Bezeichnung", text: $neueKategorie)
            Button("Abbrechen", role: .cancel) {}
            Button("Hinzufügen") {
                let _ = viewModel.addAusgabenKategorie(weg: weg, kategorie: neueKategorie)
            }
        } message: {
            Text("Beim Hinzufügen wird die Spalte sofort im Header angezeigt und im Hintergrund für alle 12 Monate angelegt.")
        }
        .sheet(item: $auslagenMonatCtx) { ctx in
            AuslagenMonatSheet(weg: weg, viewModel: viewModel, monat: ctx.monat, readonly: readonly)
        }
        .sheet(isPresented: $showAuslagenListe) {
            AuslagenGesamtListeSheet(weg: weg, viewModel: viewModel)
        }
    }
}

private struct AuslagenMonatSheet: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    let monat: Int
    let readonly: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showNeu = false
    @State private var editEintrag: AuslagenEintrag?

    private static let mn = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]

    private var eintraege: [AuslagenEintrag] {
        viewModel.auslagenEintraege(fuer: weg, monat: monat)
    }

    private var legacyEintraege: [AusgabenItem] {
        viewModel.legacyAuslagenPositionen(fuer: weg, monat: monat)
    }

    private var summe: Double {
        viewModel.summeAuslagen(fuer: weg, monat: monat)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Einträge") {
                    if eintraege.isEmpty {
                        Text("Noch keine Auslagen für diesen Monat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(eintraege) { e in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(e.verwendungszweck)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(String(format: "%.2f €", e.betrag))
                                        .font(.subheadline)
                                }
                                Text("Kaufort: \(e.kaufort)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(e.datum.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !readonly else { return }
                                editEintrag = e
                            }
                        }
                        .onDelete { idx in
                            guard !readonly else { return }
                            for i in idx {
                                viewModel.deleteAuslagenEintrag(weg: weg, eintrag: eintraege[i])
                            }
                        }
                    }
                }

                if !legacyEintraege.isEmpty {
                    Section("Alt-Einträge ohne Details") {
                        ForEach(legacyEintraege) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auslagen HM (alt)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Dieser Eintrag stammt aus der alten Struktur ohne Zweck/Kaufort.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.2f €", e.betrag))
                                    .font(.subheadline)
                            }
                        }
                        .onDelete { idx in
                            guard !readonly else { return }
                            for i in idx {
                                viewModel.deleteLegacyAuslagenPosition(weg: weg, item: legacyEintraege[i])
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Summe Monat")
                        Spacer()
                        Text(String(format: "%.2f €", summe))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Auslagen \(Self.mn[monat - 1])")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Neu") { showNeu = true }
                        .disabled(readonly)
                }
            }
        }
        .sheet(isPresented: $showNeu) {
            AuslagenNeuEintragSheet(weg: weg, viewModel: viewModel, monat: monat)
        }
        .sheet(item: $editEintrag) { eintrag in
            AuslagenBearbeitenSheet(weg: weg, viewModel: viewModel, eintrag: eintrag)
        }
    }
}

private struct AuslagenNeuEintragSheet: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    let monat: Int

    @Environment(\.dismiss) private var dismiss
    @State private var betragText: String = ""
    @State private var zweck: String = ""
    @State private var kaufort: String = ""
    @State private var datum: Date = Date()

    private var isValid: Bool {
        let betrag = Double(betragText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return betrag > 0 && !zweck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !kaufort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Neuer Auslagen-Eintrag") {
                    TextField("Betrag in €", text: $betragText)
                        .keyboardType(.decimalPad)
                    TextField("Wofür wurde gekauft?", text: $zweck)
                    TextField("Wo wurde gekauft?", text: $kaufort)
                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                }
            }
            .navigationTitle("Auslagen erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let betrag = Double(betragText.replacingOccurrences(of: ",", with: ".")) ?? 0
                        viewModel.addAuslagenEintrag(
                            weg: weg,
                            monat: monat,
                            betrag: betrag,
                            verwendungszweck: zweck.trimmingCharacters(in: .whitespacesAndNewlines),
                            kaufort: kaufort.trimmingCharacters(in: .whitespacesAndNewlines),
                            datum: datum
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

private struct AuslagenBearbeitenSheet: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    let eintrag: AuslagenEintrag

    @Environment(\.dismiss) private var dismiss
    @State private var betragText: String = ""
    @State private var zweck: String = ""
    @State private var kaufort: String = ""
    @State private var datum: Date = Date()

    private var isValid: Bool {
        let betrag = Double(betragText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return betrag > 0 && !zweck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !kaufort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Auslagen-Eintrag bearbeiten") {
                    TextField("Betrag in €", text: $betragText)
                        .keyboardType(.decimalPad)
                    TextField("Wofür wurde gekauft?", text: $zweck)
                    TextField("Wo wurde gekauft?", text: $kaufort)
                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                }
            }
            .navigationTitle("Auslage bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .appKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let betrag = Double(betragText.replacingOccurrences(of: ",", with: ".")) ?? eintrag.betrag
                        viewModel.updateAuslagenEintrag(
                            weg: weg,
                            eintrag: eintrag,
                            betrag: betrag,
                            verwendungszweck: zweck.trimmingCharacters(in: .whitespacesAndNewlines),
                            kaufort: kaufort.trimmingCharacters(in: .whitespacesAndNewlines),
                            datum: datum
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            betragText = String(format: "%.2f", eintrag.betrag)
            zweck = eintrag.verwendungszweck
            kaufort = eintrag.kaufort
            datum = eintrag.datum
        }
    }
}

private struct AuslagenGesamtListeSheet: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false

    private static let mn = ["Jan","Feb","Mär","Apr","Mai","Jun","Jul","Aug","Sep","Okt","Nov","Dez"]

    private var eintraege: [AuslagenEintrag] {
        viewModel.auslagenEintraege(fuer: weg)
    }

    private var summe: Double {
        eintraege.reduce(0.0) { $0 + $1.betrag }
    }

    var body: some View {
        NavigationStack {
            List {
                if eintraege.isEmpty {
                    Text("Keine Auslagen vorhanden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(eintraege) { e in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(Self.mn[max(1, min(12, e.monat)) - 1]) · \(e.verwendungszweck)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(String(format: "%.2f €", e.betrag))
                                    .font(.subheadline)
                            }
                            Text("Kaufort: \(e.kaufort)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(e.datum.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Gesamtsumme Auslagen")
                        Spacer()
                        Text(String(format: "%.2f €", summe))
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Alle Auslagen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showShare = true
                    } label: {
                        Label("Drucken", systemImage: "printer")
                    }
                    .disabled(eintraege.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            PDFShareSheet(
                pdfData: AuslagenListePDFRenderer.generatePDF(weg: weg, eintraege: eintraege),
                filename: "Auslagen_\(weg.abrechnungsjahr).pdf"
            )
        }
    }
}

// MARK: - Zusammenfassung

private struct ZahlungenZusammenfassung: View {
    let weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel
    @Binding var editCtx: EditCellContext?
    let readonly: Bool

    private var einnahmenGesamt: Double {
        weg.wohnungenSortiert.reduce(0) { s, w in
            s + w.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
        }
    }

    private var differenz: Double { einnahmenGesamt - ausgabenGesamt }

    private struct WohnRow {
        let name: String
        let nr: Int
        let einnahme: Double
        let ausgabe: Double
    }

    private var wohnRows: [WohnRow] {
        weg.wohnungenSortiert.map { w in
            let ein = w.zahlungen.filter { $0.monat >= 1 && $0.monat <= 12 }.reduce(0) { $0 + $1.betrag }
            let aus = w.abrechnungsErgebnis?.gesamtgebuehr ?? 0
            return WohnRow(name: w.eigentuemer, nr: w.wohnungsnummer, einnahme: ein, ausgabe: aus)
        }
    }

    private var ausgabenGesamt: Double {
        wohnRows.reduce(0) { $0 + $1.ausgabe }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Wohnungs-Übersicht
            TabellenKarte(titel: "Übersicht je Eigentümer", icon: "person.3.fill", iconColor: .blue) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        kopfZelle("Eigentümer", 130, links: true)
                        kopfZelle("Einnahmen",  88)
                        kopfZelle("Ausgaben",   88)
                        kopfZelle("Differenz",  88)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    Divider()
                    ForEach(wohnRows, id: \.nr) { row in
                        let diff = row.einnahme - row.ausgabe
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.name).font(.caption).fontWeight(.medium)
                                Text("W\(row.nr)").font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(width: 130, alignment: .leading)
                            Text(String(format: "%.2f", row.einnahme))
                                .frame(width: 88, alignment: .trailing).font(.caption)
                            Text(String(format: "%.2f", row.ausgabe))
                                .frame(width: 88, alignment: .trailing).font(.caption)
                            Text(String(format: "%.2f", diff))
                                .frame(width: 88, alignment: .trailing).font(.caption).fontWeight(.semibold)
                                .foregroundStyle(diff >= 0 ? .green : .red)
                        }
                        .padding(.vertical, 7)
                        Divider()
                    }
                    let totalDiff = einnahmenGesamt - ausgabenGesamt
                    HStack(spacing: 0) {
                        Text("Gesamt").frame(width: 130, alignment: .leading).font(.caption).fontWeight(.bold)
                        Text(String(format: "%.2f", einnahmenGesamt))
                            .frame(width: 88, alignment: .trailing).font(.caption).fontWeight(.bold).foregroundStyle(.green)
                        Text(String(format: "%.2f", ausgabenGesamt))
                            .frame(width: 88, alignment: .trailing).font(.caption).fontWeight(.bold).foregroundStyle(.orange)
                        Text(String(format: "%.2f", totalDiff))
                            .frame(width: 88, alignment: .trailing).font(.caption).fontWeight(.bold)
                            .foregroundStyle(totalDiff >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.quaternarySystemFill))
                }
                .padding(.horizontal, 12)
            }

            // Versicherungen + Jahresbilanz
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Label("Versicherungen", systemImage: "shield.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    Divider()
                    EditierbareSummZeile("Haftpflicht", wert: weg.versicherungHausHaftpflichtEuro, readonly: readonly) {
                        editCtx = EditCellContext(
                            label: "Haftpflicht",
                            aktuell: weg.versicherungHausHaftpflichtEuro,
                            speichern: { val in
                                weg.versicherungHausHaftpflichtEuro = val
                                viewModel.saveWEG()
                            }
                        )
                    }
                    Divider()
                    EditierbareSummZeile("Gebäude m. Feuer", wert: weg.versicherungGebaeudeMitFeuerEuro, readonly: readonly) {
                        editCtx = EditCellContext(
                            label: "Versicherung Gebäude",
                            aktuell: weg.versicherungGebaeudeMitFeuerEuro,
                            speichern: { val in
                                weg.versicherungGebaeudeMitFeuerEuro = val
                                viewModel.saveWEG()
                            }
                        )
                    }
                    Divider()
                    SummZeile("Summe", wert: weg.versicherungenGesamtEuro, gewicht: .bold)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    Label("Jahresbilanz", systemImage: "chart.bar.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    Divider()
                    SummZeile("Einnahmen", wert: einnahmenGesamt, farbe: .green)
                    Divider()
                    SummZeile("Ausgaben", wert: ausgabenGesamt, farbe: .orange)
                    Divider()
                    SummZeile("Differenz", wert: differenz, farbe: differenz >= 0 ? .green : .red, gewicht: .bold)
                    Divider()
                    SummZeile("Rückzahlungen", wert: differenz, farbe: differenz >= 0 ? .green : .red)
                    Divider()
                    EditierbareSummZeile("Rücklagen", wert: weg.kontoAktuellEuro, readonly: readonly) {
                        editCtx = EditCellContext(
                            label: "Rücklagen",
                            aktuell: weg.kontoAktuellEuro,
                            speichern: { val in
                                weg.kontoAktuellEuro = val
                                viewModel.saveWEG()
                            }
                        )
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct SummZeile: View {
    let label: String
    let wert: Double
    let farbe: Color
    let gewicht: Font.Weight

    init(_ label: String, wert: Double, farbe: Color = .primary, gewicht: Font.Weight = .regular) {
        self.label = label; self.wert = wert; self.farbe = farbe; self.gewicht = gewicht
    }

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.2f €", wert)).font(.caption).fontWeight(gewicht).foregroundStyle(farbe)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
    }
}

private struct EditierbareSummZeile: View {
    let label: String
    let wert: Double
    let readonly: Bool
    let onTap: () -> Void

    init(_ label: String, wert: Double, readonly: Bool = false, onTap: @escaping () -> Void) {
        self.label = label
        self.wert = wert
        self.readonly = readonly
        self.onTap = onTap
    }

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.2f €", wert))
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !readonly else { return }
            onTap()
        }
    }
}

// MARK: - Wiederverwendbare Hilfs-Views

private struct TabellenKarte<Content: View>: View {
    let titel: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(titel, systemImage: icon)
                .font(.headline)
                .foregroundStyle(iconColor)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
            content()
                .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

private struct TapZelle: View {
    let value: Double
    let width: CGFloat
    var decimals: Int = 0
    var color: Color? = nil
    let onTap: () -> Void

    var body: some View {
        Group {
            if value != 0 {
                Text(String(format: "%.*f", decimals, value))
                    .foregroundStyle(color ?? .primary)
            } else {
                Text("—").foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .font(.caption)
        .frame(width: width, alignment: .trailing)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

private func kopfZelle(_ text: String, _ width: CGFloat, links: Bool = false) -> some View {
    Text(text)
        .frame(width: width, alignment: links ? .leading : .trailing)
        .font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
        .lineLimit(1)
}
