//
//  AbrechnungListeView.swift
//  Hausverwaltung 2.0
//
//  Created by Thomas Becker on 17.04.26.
//

import SwiftUI
import SwiftData

struct AbrechnungListeView: View {
    @ObservedObject var viewModel: AbrechnungViewModel
    @Query private var eigentuemerProfileAlle: [EigentuemerProfil]
    
    var body: some View {
        NavigationStack {
            List {
                if let weg = viewModel.weg {
                    ForEach(weg.wohnungenSortiert) { wohnung in
                        NavigationLink(destination: AbrechnungDetailView(wohnung: wohnung, weg: weg)) {
                            AbrechnungListeItem(
                                wohnung: wohnung,
                                anzeigePersonen: AbrechnungsZeilenEngine.resolveHaushaltPersonen(
                                    fuer: wohnung,
                                    in: weg,
                                    eigentuemerProfile: eigentuemerProfileAlle
                                )
                            )
                        }
                    }
                }
            }
            .navigationTitle("Abrechnungen")
        }
    }
}

struct AbrechnungListeItem: View {
    let wohnung: Wohnung
    let anzeigePersonen: Int
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("W\(wohnung.wohnungsnummer)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(wohnung.eigentuemer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    Label(String(format: "%.0f m²", wohnung.flaeche_qm), systemImage: "square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(anzeigePersonen) P", systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let ergebnis = wohnung.abrechnungsErgebnis {
                    Text(String(format: "€ %.2f", ergebnis.gesamtgebuehr))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    let diff = ergebnis.zahlungsabweichung
                    let diffColor: Color = diff > 0 ? .green : (diff < 0 ? .red : .gray)
                    
                    Text(String(format: "€ %.2f", diff))
                        .font(.caption)
                        .foregroundColor(diffColor)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct AbrechnungDetailView: View {
    let wohnung: Wohnung
    let weg: WEG
    @Query private var konfigZeilenAlle: [AbrechnungsZeileKonfiguration]
    @Query private var eigentuemerProfileAlle: [EigentuemerProfil]
    @State private var showShareSheet = false
    @State private var showHeizWasserShareSheet = false

    private var vorauszahlungen: Double {
        wohnung.zahlungen
            .filter { $0.monat >= 1 && $0.monat <= 12 }
            .reduce(0) { $0 + $1.betrag }
    }

    private var reportRows: [W107Row] {
        AbrechnungsZeilenEngine.baueAusgabezeilen(
            wohnung: wohnung,
            weg: weg,
            zeilenKonfiguration: konfigZeilenAlle,
            eigentuemerProfile: eigentuemerProfileAlle
        ).map {
            W107Row(
                name: $0.name,
                total: $0.total,
                keyTotal: $0.keyTotal,
                keyLabel: $0.keyLabel,
                keyValue: $0.keyValue,
                amount: $0.amount,
                isSub: $0.isSub,
                isBold: $0.isBold
            )
        }
    }

    private var ausgabenGesamt: Double {
        reportRows.reduce(0) { $0 + $1.amount }
    }

    private var differenzbetrag: Double {
        vorauszahlungen - ausgabenGesamt
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(weg.abrechnungsTitelAnzeige)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Wohnung Nr. \(wohnung.wohnungsnummer) · \(wohnung.eigentuemer)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(weg.abrechnungsUntertitelAnzeige)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !weg.abrechnungsHeaderPunkte.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(weg.abrechnungsHeaderPunkte, id: \.self) { punkt in
                            Text("• \(punkt)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if wohnung.abrechnungsErgebnis != nil {
                    VStack(spacing: 8) {
                        ForEach(reportRows) { row in
                            W107DataRow(row: row)
                        }

                        W107TotalRow(title: "Gesamtbetrag Ausgaben", value: ausgabenGesamt)
                        W107TotalRow(title: "Vorauszahlungen " + String(weg.abrechnungsjahr), value: vorauszahlungen)
                        W107DiffRow(
                            title: "Differenzbetrag",
                            subtitle: differenzbetrag >= 0 ? "Ihr Guthaben beträgt:" : "Ihre Nachzahlung beträgt:",
                            value: differenzbetrag
                        )
                    }
                } else {
                    Text("Abrechnung noch nicht berechnet")
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Abrechnung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Einzelabrechnung PDF") {
                        showShareSheet = true
                    }
                    Button("Heiz-/Wasser Wohnung PDF") {
                        showHeizWasserShareSheet = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            PDFShareSheet(
                pdfData: AbrechnungPDFRenderer.generatePDF(
                    wohnung: wohnung,
                    weg: weg,
                    zeilenKonfiguration: konfigZeilenAlle,
                    eigentuemerProfile: eigentuemerProfileAlle
                ),
                filename: "Abrechnung_\(weg.abrechnungsjahr)_Wohnung\(wohnung.wohnungsnummer).pdf"
            )
        }
        .sheet(isPresented: $showHeizWasserShareSheet) {
            PDFShareSheet(
                pdfData: HeizWasserWohnungPDFRenderer.generatePDF(wohnung: wohnung, weg: weg),
                filename: "Heiz_Wasser_Wohnung_\(weg.abrechnungsjahr)_W\(wohnung.wohnungsnummer).pdf"
            )
        }
    }
}

struct W107Row: Identifiable {
    let id = UUID()
    let name: String
    let total: Double
    let keyTotal: Double
    let keyLabel: String
    let keyValue: Double
    let amount: Double
    let isSub: Bool
    let isBold: Bool
}

struct W107DataRow: View {
    let row: W107Row

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Bezeichnung
            Text(row.name)
                .font(.subheadline)
                .fontWeight(row.isBold ? .bold : .semibold)
                .padding(.leading, row.isSub ? 12 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 4 Spalten: Gesamt · Gesamtschlüssel · Umlageschlüssel · Ihr Anteil
            HStack(spacing: 6) {
                W107KachelSpalte(
                    label: "Gesamt",
                    wert: row.total > 0 ? String(format: "%.2f €", row.total) : "—"
                )
                W107KachelSpalte(
                    label: "Gesamtschlüssel",
                    wert: row.keyTotal > 0 ? formatSchluessel(row.keyTotal) : "—"
                )
                W107KachelSpalte(
                    label: row.keyLabel.isEmpty ? "Schlüssel" : row.keyLabel,
                    wert: row.keyValue > 0 ? formatSchluessel(row.keyValue) : "—"
                )
                W107KachelSpalte(
                    label: "Ihr Anteil",
                    wert: row.amount > 0 ? String(format: "%.2f €", row.amount) : "—",
                    hervorheben: true
                )
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

private func formatSchluessel(_ value: Double) -> String {
    if value == value.rounded() && value < 10000 {
        return String(format: "%.0f", value)
    }
    return String(format: "%.2f", value)
}

private struct W107KachelSpalte: View {
    let label: String
    let wert: String
    var hervorheben: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Text(wert)
                .font(.caption)
                .fontWeight(hervorheben ? .bold : .regular)
                .foregroundStyle(hervorheben ? Color.accentColor : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(hervorheben ? Color.accentColor.opacity(0.08) : Color(UIColor.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct W107TotalRow: View {
    let title: String
    let value: Double

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(String(format: "%.2f €", value))
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

struct W107DiffRow: View {
    let title: String
    let subtitle: String
    let value: Double

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Text(String(format: "%.2f €", value))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(value >= 0 ? Color.green : Color.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((value >= 0 ? Color.green : Color.red).opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
}

