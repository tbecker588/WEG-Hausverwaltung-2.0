//
//  AbrechnungKontrolleView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData

struct AbrechnungKontrolleView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                    Text("Kontrolle & Vergleiche")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    if let weg = viewModel.weg {
                        NavigationLink {
                            HauptabrechnungReportView(weg: weg)
                        } label: {
                            HStack {
                                Image(systemName: "tablecells")
                                Text("Hauptabrechnung (Tabellenansicht)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(AbrechnungTheme.secondaryBackground)
                            .cornerRadius(10)
                        }

                        // Hauptabrechnung Zusammenfassung
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hauptabrechnung")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Heizung gesamt")
                                        .font(.caption)
                                    Text(String(format: "%.3f Punkte", viewModel.gesamtHeizPunkte))
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Wasser Unterzähler")
                                        .font(.caption)
                                    Text(String(format: "%.3f m³", viewModel.gesamtWasserUnterzaehler))
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .background(AbrechnungTheme.secondaryBackground)
                            .cornerRadius(8)

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Hauptwasserzähler")
                                        .font(.caption)
                                    Text(String(format: "%.3f m³", viewModel.hauptwasserVerbrauch))
                                        .font(.headline)
                                }

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("Differenz")
                                        .font(.caption)
                                    Text(String(format: "%.3f m³", viewModel.wasserDifferenzHauptZuUnterzaehler))
                                        .font(.headline)
                                        .foregroundColor(viewModel.wasserDifferenzHauptZuUnterzaehler == 0 ? .primary : .orange)
                                }
                            }
                            .padding()
                            .background(AbrechnungTheme.secondaryBackground)
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(AbrechnungTheme.secondaryBackground)
                        .cornerRadius(12)
                        
                        // Differenzen Liste
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Abweichungen")
                                .font(.headline)
                            
                            ForEach(weg.wohnungenSortiert) { wohnung in
                                if let ergebnis = wohnung.abrechnungsErgebnis {
                                    HStack {
                                        Text("W\(wohnung.wohnungsnummer) - \(wohnung.eigentuemer)")
                                            .font(.caption)
                                        
                                        Spacer()
                                        
                                        let diff = ergebnis.zahlungsabweichung
                                        let diffColor: Color = diff > 0 ? .green : (diff < 0 ? .red : .gray)
                                        
                                        Text(String(format: "€ %.2f", diff))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(diffColor)
                                    }
                                    .padding()
                                    .background(AbrechnungTheme.backgroundColor)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                        .background(AbrechnungTheme.secondaryBackground)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
        }
        .navigationTitle("Kontrolle")
    }
}

struct HauptabrechnungReportView: View {
    let weg: WEG

    private var heizkosten30: Double { weg.heizkostenBrennstoffEuro * 0.3 }
    private var heizkosten70: Double { weg.heizkostenBrennstoffEuro * 0.7 }
    private var warmwasser30: Double { weg.warmwasserkostenGesamtEuro * 0.3 }
    private var warmwasser70: Double { weg.warmwasserkostenGesamtEuro * 0.7 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Heiz-, Warm- und Kaltwasserkosten Abrechnung " + String(weg.abrechnungsjahr))
                    .font(.title3)
                    .fontWeight(.bold)

                Group {
                    HauptRow(name: "Brennstoffverbrauch", value: weg.brennstoffverbrauchKwh, unit: "kWh", euro: weg.brennstoffverbrauchKwh * weg.faktorProKwhEuro)
                    HauptRow(name: "Faktor für kWh", value: weg.faktorProKwhEuro, unit: "Euro", euro: nil)
                    HauptRow(name: "Verbrauch Heizung", value: weg.verbrauchHeizungKwh, unit: "kWh", euro: nil)
                    HauptRow(name: "Verbrauch Warmwasser", value: weg.verbrauchWarmwasserKwh, unit: "kWh", euro: nil)
                    HauptRow(name: "Warmwassermenge", value: weg.warmwasserMengeM3, unit: "Kubikmeter", euro: nil)
                    HauptRow(name: "Kaltwassermenge", value: weg.kaltwasserMengeM3, unit: "Kubikmeter", euro: nil)
                    HauptRow(name: "Gesamtwassermenge", value: weg.gesamtwasserMengeM3, unit: "Kubikmeter", euro: nil)
                }

                Divider()

                Text("Trennung der Gesamtkosten Heizungsanlage")
                    .font(.headline)

                HauptKostenRow(titel: "Heizkosten", betrag: weg.heizkostenBrennstoffEuro, einheiten: weg.verbrauchHeizungKwh, preis: weg.faktorProKwhEuro)
                HauptKostenRow(titel: "Warmwasserkosten", betrag: weg.warmwasserkostenGesamtEuro, einheiten: weg.warmwasserMengeM3, preis: weg.warmwasserMengeM3 > 0 ? weg.warmwasserkostenGesamtEuro / weg.warmwasserMengeM3 : 0)
                HauptKostenRow(titel: "Kaltwasserkosten", betrag: weg.kaltwasserkostenGesamtEuro, einheiten: weg.kaltwasserMengeM3, preis: weg.kaltwasserMengeM3 > 0 ? weg.kaltwasserkostenGesamtEuro / weg.kaltwasserMengeM3 : 0)

                Divider()

                Text("Verteilung der Kosten")
                    .font(.headline)

                VerteilungRow(kostenart: "Heizkosten 30% Grundkosten", euro: heizkosten30, werte: weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm }, preisJeEinheit: weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm } > 0 ? heizkosten30 / weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm } : 0, einheit: "qm")
                VerteilungRow(kostenart: "Heizkosten 70% Verbrauchskosten", euro: heizkosten70, werte: weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch }, preisJeEinheit: weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch } > 0 ? heizkosten70 / weg.wohnungen.reduce(0) { $0 + $1.heizungVerbrauch } : 0, einheit: "Punkte")
                VerteilungRow(kostenart: "Warmwasserkosten 30% Grundkosten", euro: warmwasser30, werte: weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm }, preisJeEinheit: weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm } > 0 ? warmwasser30 / weg.wohnungen.reduce(0) { $0 + $1.flaeche_qm } : 0, einheit: "qm")
                VerteilungRow(kostenart: "Warmwasserkosten 70% Verbrauchskosten", euro: warmwasser70, werte: weg.warmwasserMengeM3, preisJeEinheit: weg.warmwasserMengeM3 > 0 ? warmwasser70 / weg.warmwasserMengeM3 : 0, einheit: "Kubikmeter")
                VerteilungRow(kostenart: "Kaltwasserkosten", euro: weg.kaltwasserkostenGesamtEuro, werte: weg.kaltwasserMengeM3, preisJeEinheit: weg.kaltwasserMengeM3 > 0 ? weg.kaltwasserkostenGesamtEuro / weg.kaltwasserMengeM3 : 0, einheit: "Kubikmeter")

                HStack {
                    Text("Gesamt")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "%.2f €", weg.gesamtkostenHeizungWasserEuro))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(10)
                .background(AbrechnungTheme.secondaryBackground)
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Hauptabrechnung")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HauptRow: View {
    let name: String
    let value: Double
    let unit: String
    let euro: Double?

    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
            Spacer()
            Text(String(format: "%.2f", value))
                .font(.caption)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            if let euro {
                Text(String(format: "%.2f €", euro))
                    .font(.caption)
                    .frame(minWidth: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HauptKostenRow: View {
    let titel: String
    let betrag: Double
    let einheiten: Double
    let preis: Double

    var body: some View {
        HStack {
            Text(titel)
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
            Text(String(format: "%.2f €", betrag))
                .font(.caption)
            Text(String(format: "%.2f", einheiten))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f €", preis))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(AbrechnungTheme.secondaryBackground)
        .cornerRadius(8)
    }
}

struct VerteilungRow: View {
    let kostenart: String
    let euro: Double
    let werte: Double
    let preisJeEinheit: Double
    let einheit: String

    var body: some View {
        HStack {
            Text(kostenart)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.2f €", euro))
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.2f %@", werte, einheit))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.2f €", preisJeEinheit))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(8)
        .background(AbrechnungTheme.secondaryBackground)
        .cornerRadius(8)
    }
}

