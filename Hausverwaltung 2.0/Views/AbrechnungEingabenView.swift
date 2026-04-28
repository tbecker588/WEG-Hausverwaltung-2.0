//
//  AbrechnungEingabenView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData

struct AbrechnungEingabenView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @State private var showHeizWasserPDFSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let weg = viewModel.weg {
                        // Schreibschutz-Banner
                        if viewModel.istJahrSchreibgeschuetzt {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.istHistorischesJahr ? "eye.fill" : "lock.fill")
                                Text(viewModel.schreibschutzHinweis)
                                    .font(.caption).fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color.orange.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        HauptabrechnungEingabeCard(weg: weg, viewModel: viewModel)
                        AbrechnungKontrollCard(weg: weg)
                        HauptwasserzaehlerCard(weg: weg, viewModel: viewModel)

                        Text("Messwerte je Wohnung")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(weg.wohnungenSortiert) { wohnung in
                            WohnungInputCard(wohnung: wohnung, viewModel: viewModel)
                        }
                    }
                }
                .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.98)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Eingaben")
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Label("Tastatur zu", systemImage: "keyboard.chevron.compact.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHeizWasserPDFSheet = true
                    } label: {
                        Image(systemName: "printer.fill")
                    }
                    .disabled(viewModel.weg == nil)
                }
            }
            .sheet(isPresented: $showHeizWasserPDFSheet) {
                if let weg = viewModel.weg {
                    PDFShareSheet(
                        pdfData: HeizWasserAbrechnungPDFRenderer.generatePDF(weg: weg),
                        filename: "Heiz_Wasser_Abrechnung_\(weg.abrechnungsjahr).pdf"
                    )
                }
            }
        }
        .appKeyboardToolbar()
    }
}

struct HauptabrechnungEingabeCard: View {
    @Bindable var weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel

    private var readonly: Bool { viewModel.istJahrSchreibgeschuetzt }

    private var brennstoffEuroBinding: Binding<Double> {
        Binding(
            get: { weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro },
            set: { neuerBetrag in
                if weg.brennstoffverbrauchKwh > 0 {
                    weg.faktorProKwhEuro = neuerBetrag / weg.brennstoffverbrauchKwh
                } else {
                    weg.faktorProKwhEuro = 0
                }
            }
        )
    }

    private var berechneterVerbrauchHeizung: Double {
        max(0, weg.brennstoffverbrauchKwh - weg.verbrauchWarmwasserKwh)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Händische Eingaben Hauptabrechnung", systemImage: "square.and.pencil")
                .font(.headline)

            Text("Diese Werte werden direkt eingetragen. Alle weiteren Felder darunter werden automatisch berechnet.")
                .font(.caption)
                .foregroundStyle(.secondary)

            EingabeGridRow(
                title: "Brennstoffverbrauch",
                unit: "kWh",
                value: $weg.brennstoffverbrauchKwh
            )

            EingabeGridRow(
                title: "Betrag laut Rechnung",
                unit: "€",
                value: brennstoffEuroBinding
            )

            EingabeGridRow(
                title: "Verbrauch Heizung f. Wasser",
                unit: "kWh",
                value: $weg.verbrauchWarmwasserKwh
            )

            AnzeigeGridRow(
                title: "Verbrauch Heizung",
                unit: "kWh",
                value: berechneterVerbrauchHeizung,
                hint: "Automatisch: Brennstoffverbrauch - Verbrauch Heizung f. Wasser"
            )

            EingabeGridRow(
                title: "Gesamtwasserbetrag",
                unit: "€",
                value: $weg.gesamtwasserbetragLtRechnungEuro
            )

            EingabeGridRow(
                title: "Wasser (Niederschlag)",
                unit: "€",
                value: $weg.niederschlagswasserEuro
            )

            Divider()

            HStack {
                Text("Faktor für kWh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.5f €", weg.faktorProKwhEuro))
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Abrechnung Gesamt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f €", weg.gesamtkostenHeizungWasserEuro))
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .disabled(readonly)
        .opacity(readonly ? 0.75 : 1.0)
        .onAppear { synchronisiereVerbrauchHeizung() }
        .onChange(of: weg.brennstoffverbrauchKwh) { synchronisiereVerbrauchHeizung() }
        .onChange(of: weg.verbrauchWarmwasserKwh) { synchronisiereVerbrauchHeizung() }
        // Hinweis: Automatische Neuberechnung bei Eingabeänderungen wurde bewusst deaktiviert,
        // damit manuell eingetragene Techem-W107-Werte nicht überschrieben werden.
        // Neuberechnung nur über den expliziten "Abrechnung berechnen"-Button.
    }

    private func synchronisiereVerbrauchHeizung() {
        let neu = berechneterVerbrauchHeizung
        if abs(weg.verbrauchHeizungKwh - neu) > 0.0001 {
            weg.verbrauchHeizungKwh = neu
            viewModel.saveWEG()
        }
    }
}

private struct EingabeGridRow: View {
    let title: String
    let unit: String
    var value: Binding<Double>

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField(unit, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}

private struct AnzeigeGridRow: View {
    let title: String
    let unit: String
    let value: Double
    let hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(format: "%.3f", value))
                    .fontWeight(.semibold)
                    .frame(width: 140, alignment: .trailing)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .leading)
            }
            if let hint, !hint.isEmpty {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AbrechnungKontrollCard: View {
    let weg: WEG

    private var gesamtFlaeche: Double { weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm } }
    private var gesamtHeizPunkte: Double { weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch } }
    private var warmwasserM3: Double { weg.warmwasserMengeM3 }
    private var kaltwasserM3: Double { weg.kaltwasserMengeM3 }

    private var heizTopf30: Double { weg.heizkostenBrennstoffEuro * 0.3 }
    private var heizTopf70: Double { weg.heizkostenBrennstoffEuro * 0.7 }
    private var wwTopf30: Double { weg.warmwasserkostenGesamtEuro * 0.3 }
    private var wwTopf70: Double { weg.warmwasserkostenGesamtEuro * 0.7 }
    private var kwTopf: Double { weg.kaltwasserkostenGesamtEuro }

    private func sumErgebnis(_ keyPath: KeyPath<AbrechnungsErgebnis, Double>) -> Double {
        weg.wohnungen.reduce(0) { sum, wohnung in
            sum + (wohnung.abrechnungsErgebnis?[keyPath: keyPath] ?? 0)
        }
    }

    private func ok(_ a: Double, _ b: Double, tol: Double = 0.02) -> Bool {
        abs(a - b) <= tol
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Automatische Verknüpfungen & Quersummen", systemImage: "checklist")
                .font(.headline)

            Text("Grün = Berechnung stimmt mit den Abrechnungswerten überein, Rot = Abweichung")
                .font(.caption)
                .foregroundStyle(.secondary)

            VerteilPruefRow(
                title: "Heizkosten 30% Grundkosten",
                euroTopf: heizTopf30,
                einheiten: gesamtFlaeche,
                preisJeEinheit: gesamtFlaeche > 0 ? heizTopf30 / gesamtFlaeche : 0,
                pruefEuro: sumErgebnis(\.heizungAnteil30Prozent),
                einheit: "qm"
            )
            VerteilPruefRow(
                title: "Heizkosten 70% Verbrauchskosten",
                euroTopf: heizTopf70,
                einheiten: gesamtHeizPunkte,
                preisJeEinheit: gesamtHeizPunkte > 0 ? heizTopf70 / gesamtHeizPunkte : 0,
                pruefEuro: sumErgebnis(\.heizungAnteil70Prozent),
                einheit: "Punkte"
            )
            VerteilPruefRow(
                title: "Warmwasser 30% Grundkosten",
                euroTopf: wwTopf30,
                einheiten: gesamtFlaeche,
                preisJeEinheit: gesamtFlaeche > 0 ? wwTopf30 / gesamtFlaeche : 0,
                pruefEuro: sumErgebnis(\.wasserAnteil30Prozent),
                einheit: "qm"
            )
            VerteilPruefRow(
                title: "Warmwasser 70% Verbrauchskosten",
                euroTopf: wwTopf70,
                einheiten: warmwasserM3,
                preisJeEinheit: warmwasserM3 > 0 ? wwTopf70 / warmwasserM3 : 0,
                pruefEuro: sumErgebnis(\.wasserAnteil70Prozent),
                einheit: "m³"
            )
            VerteilPruefRow(
                title: "Kaltwasserkosten 100%",
                euroTopf: kwTopf,
                einheiten: kaltwasserM3,
                preisJeEinheit: kaltwasserM3 > 0 ? kwTopf / kaltwasserM3 : 0,
                pruefEuro: sumErgebnis(\.kaltwasserGesamt),
                einheit: "m³"
            )

            Divider()

            let kontrollTopf = heizTopf30 + heizTopf70 + wwTopf30 + wwTopf70 + kwTopf
            let kontrollErgebnis = sumErgebnis(\.heizungGesamt) + sumErgebnis(\.wasserGesamt) + sumErgebnis(\.kaltwasserGesamt)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kontrollsumme")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Topf: \(String(format: "%.2f", kontrollTopf)) € · Abrechnung: \(String(format: "%.2f", kontrollErgebnis)) €")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(ok(kontrollTopf, kontrollErgebnis) ? "OK" : "Fehler")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ok(kontrollTopf, kontrollErgebnis) ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundStyle(ok(kontrollTopf, kontrollErgebnis) ? .green : .red)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
}

private struct VerteilPruefRow: View {
    let title: String
    let euroTopf: Double
    let einheiten: Double
    let preisJeEinheit: Double
    let pruefEuro: Double
    let einheit: String

    private var ok: Bool { abs(euroTopf - pruefEuro) <= 0.02 }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text("\(String(format: "%.2f", einheiten)) \(einheit) · \(String(format: "%.2f", preisJeEinheit)) €/Einheit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Topf \(String(format: "%.2f", euroTopf)) €")
                    .font(.caption)
                Text("Prüfung \(String(format: "%.2f", pruefEuro)) €")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ok ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HauptwasserzaehlerCard: View {
    @Bindable var weg: WEG
    @ObservedObject var viewModel: AbrechnungViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hauptwasserzähler (Keller)", systemImage: "drop.circle.fill")
            .font(.headline)
                .foregroundColor(AbrechnungTheme.wasser)

            HStack {
                VStack(alignment: .leading) {
                    Text("Anfang")
                        .font(.caption2)
                    TextField("Wert", value: $weg.hauptwasserZaehlerAnfang, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Ende")
                        .font(.caption2)
                    TextField("Wert", value: $weg.hauptwasserZaehlerEnde, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Text("Verbrauch: \(String(format: "%.3f", weg.hauptwasserVerbrauch)) m³")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Unterzähler gesamt: \(String(format: "%.3f", weg.unterzaehlerGesamtverbrauch)) m³")
                .font(.caption)
                .foregroundColor(.secondary)

            let diff = weg.wasserDifferenzHauptZuUnterzaehler
            Text("Differenz Haupt - Unterzähler: \(String(format: "%.3f", diff)) m³")
                .font(.caption)
                .foregroundColor(diff == 0 ? .secondary : .orange)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .onChange(of: weg.hauptwasserZaehlerAnfang) {
            viewModel.saveWEG()
        }
        .onChange(of: weg.hauptwasserZaehlerEnde) {
            viewModel.saveWEG()
        }
    }
}

struct WohnungInputCard: View {
    @Bindable var wohnung: Wohnung
    @ObservedObject var viewModel: AbrechnungViewModel
    @State private var expandedWohnung: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("W\(wohnung.wohnungsnummer)")
                        .font(.headline)
                    Text(wohnung.eigentuemer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: expandedWohnung == wohnung.id ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(AbrechnungTheme.secondaryBackground)
            .cornerRadius(8)
            .onTapGesture {
                withAnimation {
                    expandedWohnung = expandedWohnung == wohnung.id ? nil : wohnung.id
                }
            }
            
            // Details (bei Expand)
            if expandedWohnung == wohnung.id {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Label("Heizkostenverteiler (HKV)", systemImage: "flame.fill")
                            .foregroundColor(AbrechnungTheme.heizung)
                            .font(.caption)

                        if !wohnung.heizkostenverteiler.isEmpty {
                            ForEach(wohnung.heizkostenverteiler) { zaehler in
                                HKVZaehlerRow(zaehler: zaehler)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Jahresanfang")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.heizPunkteAnfang, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading) {
                                    Text("Jahresende")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.heizPunkteEnde, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }

                        Text("Heizpunkte gesamt: \(String(format: "%.3f", wohnung.heizungVerbrauch))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AbrechnungTheme.heizung.opacity(0.05))
                    .cornerRadius(6)

                    VStack(spacing: 8) {
                        Label("Wasserzähler (Warm/Kalt/WK)", systemImage: "drop.fill")
                            .foregroundColor(AbrechnungTheme.wasser)
                            .font(.caption)

                        if !wohnung.wasserzaehler.isEmpty {
                            ForEach(wohnung.wasserzaehler) { zaehler in
                                WasserZaehlerRow(zaehler: zaehler)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Wohnung Anfang")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.wasserWohnungZaehlerAnfang, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading) {
                                    Text("Wohnung Ende")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.wasserWohnungZaehlerEnde, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Waschküche Anfang")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.wasserWaschkuecheZaehlerAnfang, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading) {
                                    Text("Waschküche Ende")
                                        .font(.caption2)
                                    TextField("Wert", value: $wohnung.wasserWaschkuecheZaehlerEnde, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }

                        Text("Wasser Wohnung+Kalt/Warm: \(String(format: "%.3f", wohnung.wasserWohnungVerbrauch)) m³")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Wasser Waschküche: \(String(format: "%.3f", wohnung.wasserWaschkuecheVerbrauch)) m³")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Gesamt Wasser Wohnung: \(String(format: "%.3f", wohnung.wasserVerbrauch)) m³")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AbrechnungTheme.wasser.opacity(0.05))
                    .cornerRadius(6)
                }
                .padding()
                .background(AbrechnungTheme.backgroundColor)
            }
        }
        .background(AbrechnungTheme.secondaryBackground)
        .cornerRadius(12)
        .onChange(of: wohnung.heizPunkteAnfang) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.heizPunkteEnde) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserWohnungZaehlerAnfang) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserWohnungZaehlerEnde) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserWaschkuecheZaehlerAnfang) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserWaschkuecheZaehlerEnde) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.heizkostenverteiler.count) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserzaehler.count) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.heizungVerbrauch) {
            viewModel.saveWEG()
        }
        .onChange(of: wohnung.wasserVerbrauch) {
            viewModel.saveWEG()
        }
    }
}

struct HKVZaehlerRow: View {
    @Bindable var zaehler: HeizkostenverteilerZaehler

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Nr. \(zaehler.nummer)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(zaehler.bezeichnung)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if !zaehler.heizungstyp.isEmpty {
                Text(zaehler.heizungstyp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !zaehler.hinweis.isEmpty {
                Text(zaehler.hinweis)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Faktor")
                        .font(.caption2)
                    TextField("", value: $zaehler.faktor, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("Neu")
                        .font(.caption2)
                    TextField("", value: $zaehler.ablesewertNeu, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("Punkte")
                        .font(.caption2)
                    TextField("", value: $zaehler.verbrauchPunkte, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.001))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AbrechnungTheme.heizung.opacity(0.25), lineWidth: 1))
    }
}

struct WasserZaehlerRow: View {
    @Bindable var zaehler: Wasserzaehler

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Nr. \(zaehler.nummer)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(zaehler.art.rawValue) · \(zaehler.bezeichnung)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if !zaehler.typ.isEmpty {
                Text(zaehler.typ)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Alt")
                        .font(.caption2)
                    TextField("", value: $zaehler.ablesewertAlt, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("Neu")
                        .font(.caption2)
                    TextField("", value: $zaehler.ablesewertNeu, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("m³")
                        .font(.caption2)
                    Text(String(format: "%.3f", zaehler.verbrauch))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AbrechnungTheme.secondaryBackground)
                        .cornerRadius(6)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.001))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AbrechnungTheme.wasser.opacity(0.25), lineWidth: 1))
    }
}

